/* Real Chromium smoke test of the compiled Flutter web app. No private data. */
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
    const context = await browser.newContext({viewport: {width: 390, height: 844}, deviceScaleFactor: 1, locale: 'en-US'});
    page = await context.newPage();
    const remoteRequests = new Set(), errors = [];
    page.on('request', request => {
      const url = new URL(request.url());
      if (['http:', 'https:'].includes(url.protocol) && !['127.0.0.1', 'localhost'].includes(url.hostname)) remoteRequests.add(url.origin);
    });
    page.on('pageerror', error => errors.push(error.message));
    async function ready() {
      await page.waitForSelector('#splash', {state: 'detached', timeout: 90000});
      await page.locator('flt-semantics-placeholder, flt-semantics').first().waitFor({state: 'attached', timeout: 90000});
      const placeholder = page.locator('flt-semantics-placeholder');
      if (await placeholder.count()) await placeholder.evaluate(element => element.click());
    }
    await page.goto('http://127.0.0.1:8080', {waitUntil: 'domcontentloaded'});
    await ready();
    await page.getByRole('button', {name: 'Continue', exact: true}).click({timeout: 20000});
    await page.getByRole('textbox').first().fill('Demo User');
    await page.getByRole('button', {name: 'Continue', exact: true}).click();
    const demoToggle = page.getByRole('switch').or(page.getByRole('checkbox')).first();
    await demoToggle.click();
    await page.getByRole('button', {name: 'Get started', exact: true}).click();
    await page.getByText('Total net worth', {exact: false}).first().waitFor({timeout: 30000});
    // Deliberately small diagnostic image; downloadable full sources remain separate.
    for (const quality of [50, 35, 20, 10]) {
      const jpg = await page.screenshot({type: 'jpeg', quality, animations: 'disabled'});
      fs.writeFileSync('web-dashboard.jpg', jpg);
      if (jpg.length < 35000) break;
    }
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
    if (errors.length) throw new Error('Uncaught browser errors: ' + errors.join('\n'));
    console.log('::notice title=Web smoke::PASS: demo onboarding, persisted browser reload, offline reload, and no external runtime requests.');
  } catch (error) {
    if (page) {
      console.log('Page text:', (await page.locator('body').innerText().catch(() => '')).slice(-8000));
      console.log('Input labels:', await page.locator('input').evaluateAll(inputs => inputs.map(input => ({label: input.getAttribute('aria-label'), type: input.type}))).catch(() => []));
      await page.screenshot({path: 'web-failure.jpg', type: 'jpeg', quality: 30}).catch(() => {});
    }
    console.error(error);
    process.exitCode = 1;
  } finally {
    if (browser) await browser.close();
    server.kill('SIGTERM');
  }
})();
