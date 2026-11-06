/* Chromium smoke test. Only new, fictional demo records are ever used. */
const {createRequire} = require('node:module');
const {spawn} = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const deps = createRequire(path.join(process.env.PAISA_SMOKE_DEPS || '/tmp/paisa-web-smoke', 'package.json'));
const {chromium: playwright} = deps('playwright-core');
const {PNG} = deps('pngjs');
const chromiumModule = deps('@sparticuz/chromium');
const binary = chromiumModule.default || chromiumModule;

(async () => {
  const server = spawn('python3', ['-m', 'http.server', '8080', '--bind', '0.0.0.0', '--directory', 'build/web'], {stdio: 'ignore'});
  let browser, page;
  const errors = [];
  async function capture(name) {
    await page.mouse.move(1, 843);
    await page.waitForTimeout(180);
    const full = await page.screenshot({type: 'jpeg', quality: 60, animations: 'disabled'});
    fs.writeFileSync(name, full);
    // Full-size evidence stays in the artifact. API annotations have a 50-item
    // job cap: bounded <=6.75KB thumbnails are split across two review jobs.
    const thumbnail = await page.evaluate(async encoded => {
      const image = new Image();
      await new Promise((resolve, reject) => { image.onload = resolve; image.onerror = reject; image.src = 'data:image/jpeg;base64,' + encoded; });
      let result;
      for (const width of [312, 280, 240]) {
        const canvas = document.createElement('canvas');
        canvas.width = width; canvas.height = Math.round(image.height / image.width * width);
        canvas.getContext('2d').drawImage(image, 0, 0, canvas.width, canvas.height);
        for (const quality of [0.20, 0.12, 0.07]) {
          result = canvas.toDataURL('image/jpeg', quality).split(',')[1];
          if (result.length <= 9000) return result;
        }
      }
      return result;
    }, full.toString('base64'));
    fs.writeFileSync(name.replace('.jpg', '-thumb.jpg'), Buffer.from(thumbnail, 'base64'));
  }
  try {
    for (let i = 0; i < 40; i++) {
      try { if ((await fetch('http://127.0.0.1:8080')).ok) break; } catch (_) {}
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    browser = await playwright.launch({executablePath: await binary.executablePath(), args: binary.args, headless: true});
    const context = await browser.newContext({viewport: {width: 390, height: 844}, deviceScaleFactor: 1, locale: 'en-IN', colorScheme: 'light', hasTouch: true});
    page = await context.newPage();
    const remoteRequests = new Set();
    page.on('request', request => {
      const url = new URL(request.url());
      if (['http:', 'https:'].includes(url.protocol) && !['127.0.0.1', 'localhost'].includes(url.hostname)) remoteRequests.add(url.href);
    });
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {
      if (/A RenderFlex overflowed|EXCEPTION CAUGHT BY|DartError/.test(message.text())) errors.push(message.text());
    });
    async function ready() {
      await page.waitForSelector('#splash', {state: 'detached', timeout: 90000});
      await page.locator('flt-semantics-placeholder, flt-semantics').first().waitFor({state: 'attached', timeout: 90000});
      const placeholder = page.locator('flt-semantics-placeholder');
      if (await placeholder.count()) await placeholder.evaluate(element => element.click());
    }
    async function scroll(delta) {
      // A capture moves the pointer off cards; wheel over the real scroll body.
      await page.mouse.move(210, 500);
      await page.mouse.wheel(0, delta);
    }
    async function assertDarkPalette() {
      const shot = PNG.sync.read(await page.screenshot({type: 'png'}));
      const offset = (110 * shot.width + 4) * 4;
      const rgb = [...shot.data.subarray(offset, offset + 3)];
      if (rgb.some((value, i) => Math.abs(value - [35, 26, 21][i]) > 6)) {
        throw new Error('Dark palette was not applied/persisted: ' + rgb.join(','));
      }
    }
    async function nav(label, contains = false) {
      // Do not wheel a newly pushed route while Flutter's 300ms transition hides semantics.
      await page.waitForTimeout(350);
      const name = new RegExp((contains ? '' : '^') + label);
      const target = page.getByRole('button', {name}).or(page.getByRole('tab', {name})).or(page.getByLabel(name)).or(page.getByText(name)).last();
      // Flutter only exposes painted semantics nodes; DOM scrollIntoView cannot
      // materialize an offscreen SliverGrid item. Scroll its real canvas first.
      if (!await target.isVisible()) {
        await page.mouse.move(200, 440);
        await scroll(-20000);
        await page.waitForTimeout(220);
      }
      for (let attempt = 0; attempt < 8 && !await target.isVisible(); attempt++) {
        await page.mouse.move(200, 440);
        await scroll(400);
        await page.waitForTimeout(180);
      }
      // A painted sliver can still be partially behind the toolbar/demo exit.
      // Frame it with a real scroll, rather than clicking through that overlay.
      const box = await target.boundingBox();
      if (box && box.y + box.height / 2 < 152) {
        await scroll(box.y - 168);
        await page.waitForTimeout(250);
      }
      // Generated Flutter grouping nodes can overlap semantic buttons in the DOM.
      // A real canvas-coordinate click still exercises Flutter's pointer hit test.
      await target.click({timeout: 15000, force: ['Light', 'Dark', 'Just Black', 'System'].includes(label)});
      await page.waitForTimeout(350);
    }
    async function goBack() {
      // Consecutive pops must not reuse the departing route's semantics node.
      // Flutter hides/remounts those nodes during its 300ms route transition.
      await page.mouse.move(1, 843);
      await page.waitForTimeout(350);
      await page.getByRole('button', {name: 'Back', exact: true}).click();
      await page.mouse.move(1, 843);
      await page.waitForTimeout(350);
    }
    function visibleText(label) {
      // Read-only chart/card semantics may merge title and values into one label.
      const name = new RegExp(label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
      return page.getByText(label, {exact: false}).or(page.getByLabel(name)).first();
    }
    async function revealText(label, top = 152) {
      // Flutter can expose a heading as an aria-labeled group, not DOM text.
      const name = new RegExp('^' + label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '(?:\\s|$)');
      const target = page.getByText(name).or(page.getByLabel(name)).first();
      await scroll(-20000); await page.waitForTimeout(220);
      for (let i = 0; i < 22 && !await target.isVisible(); i++) {
        await scroll(360); await page.waitForTimeout(180);
      }
      await target.waitFor({state: 'visible', timeout: 10000});
      const box = await target.boundingBox();
      if (box && box.y > top) { await scroll(box.y - top); await page.waitForTimeout(250); }
    }
    const touch = await context.newCDPSession(page);
    await touch.send('Emulation.setTouchEmulationEnabled', {enabled: true, maxTouchPoints: 1});
    async function swipeCarousel(y) {
      // Coordinates are relative to the navigator, below the reserved demo band.
      const exitBox = await page.getByRole('button', {name: 'Exit Demo', exact: true}).boundingBox();
      y += exitBox ? exitBox.y + exitBox.height + 4 : 0;
      await touch.send('Input.dispatchTouchEvent', {type: 'touchStart', touchPoints: [{x: 325, y}]});
      for (let i = 1; i <= 10; i++) {
        await touch.send('Input.dispatchTouchEvent', {type: 'touchMove', touchPoints: [{x: 325 - i * 26, y}]});
        await page.waitForTimeout(25);
      }
      await touch.send('Input.dispatchTouchEvent', {type: 'touchEnd', touchPoints: []});
      await page.waitForTimeout(650);
    }
    await page.goto('http://127.0.0.1:8080', {waitUntil: 'domcontentloaded'});
    await ready();
    await page.getByRole('button', {name: 'Start fresh', exact: true}).waitFor();
    await capture('web-intro.jpg');
    // Verify a separate 2026 demo first, then preserve the original reference
    // journeys and 14-step real setup below unchanged. Exit must restore welcome.
    await require('./reference_2026_smoke.cjs')({page, nav, goBack, capture, scroll, revealText, visibleText});
    await page.getByRole('button', {name: 'Try Demo Mode', exact: true}).click();
    await page.getByText('Demo User', {exact: false}).first().waitFor({timeout: 30000});
    await page.waitForTimeout(800);
    await capture('web-dashboard.jpg');
    await page.mouse.move(200, 550); await scroll(650); await page.waitForTimeout(450);
    await capture('web-home-tools.jpg');
    await scroll(450); await page.waitForTimeout(450); await capture('web-home-tools-more.jpg');
    await scroll(400); await page.waitForTimeout(450); await capture('web-home-grid.jpg');
    await scroll(3000); await page.waitForTimeout(450);
    await capture('web-home-lower.jpg');
    await revealText('Templates'); await capture('web-home-templates.jpg');
    await revealText('Calendar heatmap'); await capture('web-home-heatmap.jpg');
    await revealText('Trend'); await capture('web-home-trend.jpg');
    await revealText('Track budgets'); await capture('web-home-budgets.jpg');
    await revealText('Upcoming transactions'); await capture('web-home-upcoming.jpg');
    await page.getByRole('button', {name: 'See all', exact: true}).last().click();
    await page.waitForTimeout(350); await capture('web-upcoming-all.jpg');
    await goBack();
    await nav('Budgets'); await capture('web-budgets.jpg');
    await swipeCarousel(180);
    await page.getByText(/^On Track(?:\s|$)/).or(page.getByLabel(/^On Track(?:\s|$)/)).first().waitFor();
    await capture('web-budget-status.jpg');
    await page.getByRole('button', {name: 'How budgets work', exact: true}).click();
    await page.waitForTimeout(350); await capture('web-budget-help.jpg');
    await scroll(1500); await page.waitForTimeout(350); await capture('web-budget-help-bottom.jpg');
    await page.getByRole('button', {name: 'Got it', exact: true}).click();
    await nav('Getting around');
    await visibleText('Budget Progress').waitFor();
    await capture('web-budget-detail.jpg');
    await scroll(700); await page.waitForTimeout(400); await capture('web-budget-breakdown.jpg');
    await goBack();
    await goBack();
    await scroll(-20000); await page.waitForTimeout(300);
    await nav('Accounts');
    await visibleText('Total balance').waitFor();
    await capture('web-accounts.jpg');
    await swipeCarousel(175);
    await page.getByText(/^Pocket money(?:\s|$)/).or(page.getByLabel(/^Pocket money(?:\s|$)/)).first().waitFor();
    await capture('web-accounts-second.jpg');
    await nav('Reports');
    await visibleText('Quick Insights').waitFor();
    await capture('web-reports.jpg');
    await revealText('Daily bar chart');
    await visibleText('Bar chart. Expense, Income.').waitFor();
    await capture('web-flow.jpg');
    await page.getByRole('button', {name: 'Daily line chart', exact: true}).click();
    await visibleText('Line chart. Expense, Income.').waitFor();
    await capture('web-report-line.jpg');
    await page.getByRole('button', {name: 'Daily bar chart', exact: true}).click();
    await visibleText('Bar chart. Expense, Income.').waitFor();
    await scroll(450); await page.waitForTimeout(650);
    await capture('web-allocation.jpg');
    for (const [label, suffix] of [['Month Summary', 'month'], ['Category Breakdown', 'category'], ['Budget Performance', 'budget'], ['Cash Flow Analysis', 'cashflow'], ['Goal Progress', 'goal']]) {
      await nav(label);
      const name = new RegExp('^' + label + '(?:\\s|$)');
      await page.getByText(name).or(page.getByLabel(name)).first().waitFor();
      await capture('web-financial-' + suffix + '.jpg');
      await goBack();
    }
    await nav('Home');
    await page.getByRole('button', {name: 'All tools', exact: true}).click();
    await nav('Recurring');
    await capture('web-recurring.jpg');
    await nav('Calendar');
    await page.getByRole('button', {name: 'Next month', exact: true}).click();
    await page.getByRole('button', {name: 'Previous month', exact: true}).click();
    await scroll(350); await page.waitForTimeout(350);
    await capture('web-calendar.jpg');
    await page.getByRole('button', {name: 'How recurring works', exact: true}).click();
    await capture('web-help.jpg');
    await page.mouse.move(210, 520); await scroll(1600); await page.waitForTimeout(300);
    await capture('web-help-bottom.jpg');
    await page.getByRole('button', {name: 'Got it', exact: true}).click();
    await nav('Due'); await nav('All');
    await nav('Netflix');
    await page.getByRole('button', {name: 'Process', exact: true}).waitFor();
    await capture('web-detail.jpg');
    await page.mouse.move(210, 600); await scroll(1000); await page.waitForTimeout(400);
    await capture('web-history.jpg');
    await scroll(-20000); await page.waitForTimeout(300);
    await page.getByRole('button', {name: 'Process', exact: true}).click();
    await page.waitForTimeout(500);
    await page.getByRole('button', {name: 'Recurring options', exact: true}).click();
    await page.getByRole('menuitem', {name: 'Archive', exact: true}).or(page.getByText('Archive', {exact: true})).last().click();
    await page.waitForTimeout(300);
    await goBack();
    await nav('Archived');
    await capture('web-archived.jpg');
    await require('./reference_batch_03_smoke.cjs')({page, nav, goBack, capture, scroll, revealText, visibleText, swipeCarousel});
    await require('./reference_batch_04_smoke.cjs')({page, nav, goBack, capture, scroll, revealText, visibleText, swipeCarousel});
    await page.getByRole('button', {name: 'Exit Demo', exact: true}).click();
    await page.getByRole('button', {name: 'Start fresh', exact: true}).waitFor();
    // A demo edit must not leave a real profile behind. Now complete all 14 steps.
    await page.getByRole('button', {name: 'Start fresh', exact: true}).click();
    await page.waitForTimeout(350);
    await page.getByRole('button', {name: 'Get started', exact: true}).click();
    await page.waitForTimeout(350);
    // Tour grouping semantics may overlap the CTA in the DOM. A forced click
    // still uses Flutter's real canvas hit test; subsequent steps verify navigation.
    for (let index = 2; index <= 10; index++) {
      if (index === 2) await capture('web-budget-tour.jpg');
      if (index === 3) await capture('web-loan-tour.jpg');
      if (index === 4) await capture('web-goal-tour.jpg');
      if (index === 6) await capture('web-category-tour.jpg');
      if (index === 7) await capture('web-languages.jpg');
      if (index === 9) await capture('web-notifications.jpg');
      await page.getByRole('button', {name: 'Next', exact: true}).click({force: true});
      await page.waitForTimeout(350);
    }
    await page.getByRole('button', {name: 'Continue', exact: true}).click({force: true});
    const name = page.getByRole('textbox', {name: 'What should we call you?', exact: true}).first();
    await name.click(); await page.waitForTimeout(400);
    await page.keyboard.press('ControlOrMeta+A'); await page.keyboard.press('Backspace');
    await page.keyboard.type('Browser User', {delay: 30});
    if (await name.inputValue() !== 'Browser User') throw new Error('Onboarding name draft was not received intact');
    await page.keyboard.press('Tab'); await page.waitForTimeout(200);
    await page.getByRole('button', {name: 'Continue', exact: true}).click({force: true});
    await page.getByRole('button', {name: 'Start using Tink', exact: true}).click({force: true});
    await page.getByText('Browser User', {exact: false}).first().waitFor({timeout: 30000});
    if (await page.getByRole('button', {name: 'Exit Demo', exact: true}).isVisible()) throw new Error('Real setup retained a demo overlay');
    await page.getByRole('button', {name: 'Profiles & settings', exact: true}).click();
    await nav('Settings'); await nav('Appearance'); await nav('Light');
    await nav('Dark');
    await assertDarkPalette();
    await page.reload({waitUntil: 'domcontentloaded'});
    await ready();
    await page.getByText('Browser User', {exact: false}).first().waitFor({timeout: 20000});
    await page.waitForTimeout(700); await assertDarkPalette();
    await capture('web-dark.jpg');
    await page.evaluate(async () => {
      await navigator.serviceWorker.ready;
      if (!navigator.serviceWorker.controller) await new Promise((resolve, reject) => {
        navigator.serviceWorker.addEventListener('controllerchange', resolve, {once: true});
        setTimeout(() => reject(new Error('Offline cache did not take control')), 30000);
      });
    });
    await context.setOffline(true);
    await page.reload({waitUntil: 'domcontentloaded'});
    await ready();
    await page.getByText('Browser User', {exact: false}).first().waitFor({timeout: 30000});
    await assertDarkPalette();
    if (remoteRequests.size) throw new Error('Unexpected runtime network hosts: ' + [...remoteRequests].join(', '));
    if (errors.length) throw new Error('Browser/layout errors: ' + errors.join('\n'));
    console.log('::notice title=Tink web smoke::PASS: isolated editable demo and exit, real 14-step setup, live feature previews, Home grid, Home heatmap/trend/tracked budgets/upcoming, account carousels/month reports/all five financial reports, budget overview/status/help/detail, recurring calendar/help/history/process/archive, theme persistence, offline reload and zero external runtime requests.');
  } catch (error) {
    if (page) {
      console.log('Browser errors:', errors);
      console.log('Page text:', (await page.locator('body').innerText().catch(() => '')).slice(-8000));
      console.log('Aria labels:', JSON.stringify(await page.locator('[aria-label]').evaluateAll(nodes => nodes.map(n => ({role: n.getAttribute('role'), label: n.getAttribute('aria-label')})).filter(n => n.label).slice(-60)).catch(() => [])));
      console.log('Back semantics:', JSON.stringify(await page.getByText('Back', {exact: true}).evaluateAll(nodes => nodes.map(n => ({html: n.outerHTML.slice(0, 1200), hidden: !!n.closest('[aria-hidden="true"]'), rect: n.getBoundingClientRect().toJSON()}))).catch(() => [])));
      console.log('Demo input diagnostics:', await page.locator('input').evaluateAll(inputs => inputs.map(input => ({label: input.getAttribute('aria-label'), value: input.value, type: input.type}))).catch(() => []));
      await capture('web-failure.jpg').catch(() => {});
    }
    console.error(error);
    process.exitCode = 1;
  } finally {
    if (browser) await browser.close();
    server.kill('SIGTERM');
  }
})();
