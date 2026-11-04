/* Chromium smoke test. Only new, fictional demo records are ever used. */
const {createRequire} = require('node:module');
const {spawn} = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const deps = createRequire(path.join(process.env.PAISA_SMOKE_DEPS || '/tmp/paisa-web-smoke', 'package.json'));
const {chromium: playwright} = deps('playwright-core');
const chromiumModule = deps('@sparticuz/chromium');
const binary = chromiumModule.default || chromiumModule;

(async () => {
  const server = spawn('python3', ['-m', 'http.server', '8080', '--bind', '0.0.0.0', '--directory', 'build/web'], {stdio: 'ignore'});
  let browser, page;
  try {
    for (let i = 0; i < 40; i++) {
      try { if ((await fetch('http://127.0.0.1:8080')).ok) break; } catch (_) {}
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    browser = await playwright.launch({executablePath: await binary.executablePath(), args: binary.args, headless: true});
    const context = await browser.newContext({viewport: {width: 390, height: 844}, deviceScaleFactor: 1, locale: 'en-IN', colorScheme: 'light'});
    page = await context.newPage();
    const remoteRequests = new Set(), errors = [];
    page.on('request', request => {
      const url = new URL(request.url());
      if (['http:', 'https:'].includes(url.protocol) && !['127.0.0.1', 'localhost'].includes(url.hostname)) remoteRequests.add(url.origin);
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
    async function capture(name) {
      await page.mouse.move(2, 2);
      await page.waitForTimeout(180);
      for (const quality of [50, 35, 20, 10]) {
        const jpg = await page.screenshot({type: 'jpeg', quality, animations: 'disabled'});
        fs.writeFileSync(name, jpg);
        if (jpg.length < 35000) break;
      }
    }
    async function nav(label) {
      const name = new RegExp('^' + label);
      const target = page.getByRole('button', {name}).or(page.getByRole('tab', {name})).or(page.getByLabel(name)).or(page.getByText(name)).last();
      // Flutter only exposes painted semantics nodes; DOM scrollIntoView cannot
      // materialize an offscreen SliverGrid item. Scroll its real canvas first.
      for (let attempt = 0; attempt < 8 && !await target.isVisible(); attempt++) {
        await page.mouse.move(200, 440);
        await page.mouse.wheel(0, 400);
        await page.waitForTimeout(180);
      }
      await target.click({timeout: 15000});
    }
    await page.goto('http://127.0.0.1:8080', {waitUntil: 'domcontentloaded'});
    await ready();
    await page.getByRole('button', {name: 'Continue', exact: true}).waitFor();
    await capture('web-intro.jpg');
    for (let i = 0; i < 5; i++) {
      await page.getByRole('button', {name: 'Continue', exact: true}).click();
      // Allow this deliberate finite PageView slide to complete before advancing.
      await page.waitForTimeout(350);
    }
    await page.getByRole('button', {name: 'Get started', exact: true}).click();
    const name = page.getByRole('textbox', {name: 'What should we call you?', exact: true}).first();
    await name.click();
    await page.keyboard.type('Demo User', {delay: 45});
    await page.keyboard.press('Tab');
    await page.getByRole('button', {name: 'Continue', exact: true}).click();
    // SwitchListTile merges its text into its accessible name, not a DOM text node.
    await page.getByRole('switch').or(page.getByRole('checkbox')).first().click();
    await page.getByRole('button', {name: 'Start using Tink', exact: true}).click();
    const celebration = page.getByRole('button', {name: 'A little proud of myself', exact: true});
    if (await celebration.isVisible()) await celebration.click();
    await page.getByRole('button', {name: 'How safe to spend is calculated', exact: true}).waitFor({timeout: 30000});
    await page.waitForTimeout(800);
    if (await page.getByText('Unsupported finance link', {exact: false}).isVisible()) throw new Error('Ordinary web startup was mistaken for a finance intent');
    await capture('web-dashboard.jpg');
    await nav('Accounts');
    await page.getByLabel(/Your money, in one place/).or(page.getByText('Your money, in one place', {exact: false})).first().waitFor();
    await capture('web-accounts.jpg');
    await nav('More');
    await nav('Reports');
    await page.getByLabel(/Your money, a little clearer/).or(page.getByText('Your money, a little clearer', {exact: false})).first().waitFor();
    await page.waitForTimeout(650);
    await capture('web-reports.jpg');
    await page.getByRole('button', {name: 'Back', exact: true}).click();
    await nav('Settings');
    await nav('Appearance');
    await nav('Dark');
    await page.getByRole('button', {name: 'Back', exact: true}).click();
    await page.getByRole('button', {name: 'Back', exact: true}).click();
    await nav('Home');
    await page.getByRole('button', {name: 'How safe to spend is calculated', exact: true}).waitFor();
    await page.waitForTimeout(700);
    await capture('web-dark.jpg');
    await page.reload({waitUntil: 'domcontentloaded'});
    await ready();
    await page.getByText('Demo User', {exact: false}).first().waitFor({timeout: 20000});
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
    await page.getByText('Demo User', {exact: false}).first().waitFor({timeout: 30000});
    if (remoteRequests.size) throw new Error('Unexpected runtime network hosts: ' + [...remoteRequests].join(', '));
    if (errors.length) throw new Error('Browser/layout errors: ' + errors.join('\n'));
    console.log('::notice title=Tink web smoke::PASS: six intros, real demo onboarding, accounts, reports, dark theme, persisted reload, offline reload and zero external runtime requests.');
  } catch (error) {
    if (page) {
      console.log('Page text:', (await page.locator('body').innerText().catch(() => '')).slice(-8000));
      console.log('Aria labels:', JSON.stringify(await page.locator('[aria-label]').evaluateAll(nodes => nodes.map(n => ({role: n.getAttribute('role'), label: n.getAttribute('aria-label')})).filter(n => n.label).slice(-60)).catch(() => [])));
      console.log('Demo input diagnostics:', await page.locator('input').evaluateAll(inputs => inputs.map(input => ({label: input.getAttribute('aria-label'), value: input.value, type: input.type}))).catch(() => []));
      await page.screenshot({path: 'web-failure.jpg', type: 'jpeg', quality: 30}).catch(() => {});
    }
    console.error(error);
    process.exitCode = 1;
  } finally {
    if (browser) await browser.close();
    server.kill('SIGTERM');
  }
})();
