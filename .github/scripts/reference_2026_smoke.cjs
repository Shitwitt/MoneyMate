/* 2026 workflow checks use a NEW isolated demo and a fictional legacy fixture. */
module.exports = async function reference2026({page, nav, goBack, capture, scroll, revealText, visibleText}) {
  const fs = require('node:fs');
  const path = require('node:path');
  const button = name => page.getByRole('button', {name, exact: true});
  const pause = async () => {await page.mouse.move(1, 843); await page.waitForTimeout(400);};
  const shot = async name => {await pause(); await capture('web-2026-' + name + '.jpg');};
  async function input(label, text) {
    const field = page.getByRole('textbox', {name: label}).first();
    await field.click(); await page.waitForTimeout(250);
    await page.keyboard.press('ControlOrMeta+A'); await page.keyboard.press('Backspace');
    await page.keyboard.type(text, {delay: 25});
    if (await field.inputValue() !== text) throw new Error('2026 draft was not received intact: ' + label);
  }
  async function settings() {
    await button('Profiles & settings').click(); await nav('Settings');
  }
  async function focusedLabel() {
    return page.evaluate(() => document.activeElement?.getAttribute('aria-label') || '');
  }
  function csvRows(text) {
    const rows = []; let row = [], cell = '', quoted = false;
    for (let i = 0; i < text.length; i++) {
      const c = text[i];
      if (c === '"') {if (quoted && text[i + 1] === '"') {cell += '"'; i++;} else quoted = !quoted;}
      else if (!quoted && c === ',') {row.push(cell); cell = '';}
      else if (!quoted && (c === '\n' || c === '\r')) {
        if (c === '\r' && text[i + 1] === '\n') i++;
        row.push(cell); rows.push(row); row = []; cell = '';
      } else cell += c;
    }
    if (quoted) throw new Error('Malformed downloaded CSV');
    if (cell || row.length) {row.push(cell); rows.push(row);}
    return rows;
  }

  const failures = [];
  async function scenario(name, run) {
    try {
      await button('Start fresh').waitFor();
      await button('Try Demo Mode').click();
      await visibleText('Demo User').waitFor(); await pause();
      await run();
      console.log('2026 scenario passed: ' + name);
    } catch (error) {
      const dom = await page.evaluate(() => ({
        buttons: [...document.querySelectorAll('[role="button"]')].map(el => el.getAttribute('aria-label') || el.textContent).slice(0, 28),
        labels: [...document.querySelectorAll('[aria-label]')].map(el => ({role: el.getAttribute('role'), label: el.getAttribute('aria-label')})).slice(0, 22),
        focus: document.activeElement?.getAttribute('aria-label'),
      }));
      failures.push(name + ': ' + error.message + '\n' + JSON.stringify(dom).slice(0, 4200));
      try {await shot('failed-' + name);} catch (_) {}
    } finally {
      // Every case owns a fresh temporary demo; one locator failure must not
      // prevent the other actual workflows from exposing their own problems.
      for (let i = 0; i < 2; i++) {await page.keyboard.press('Escape'); await page.waitForTimeout(100);}
      await page.setViewportSize({width: 390, height: 844});
      if (await button('Exit Demo').isVisible()) await button('Exit Demo').click();
      await button('Start fresh').waitFor({timeout: 15000});
    }
  }

  await scenario('home-reorder', async () => {
    await button('Reorder Home cards').click();
    await visibleText('Make Home yours').waitFor(); await shot('home-reorder');
    await button('Move Total balance down').click(); await pause();
    const first = page.getByLabel(/^Income & expenses\nDrag Income & expenses(?:\n|$)/);
    const second = page.getByLabel(/^Total balance\nDrag Total balance(?:\n|$)/);
    const firstBox = await first.boundingBox(), secondBox = await second.boundingBox();
    if (!firstBox || !secondBox || firstBox.y >= secondBox.y) throw new Error('Home order was not updated inline');
    await shot('home-reordered');
    await button('Finish reordering').click(); await pause();
  });

  await scenario('privacy-shortcuts', async () => {
    await settings(); await nav('Privacy & security'); await nav('Hide amounts');
    await goBack(); await goBack();
    const hidden = page.getByLabel(/Amount hidden/);
    if (!await hidden.count()) throw new Error('Private amounts did not expose shape-mask semantics');
    await shot('privacy');
    await settings(); await nav('Privacy & security'); await nav('Hide amounts'); await goBack();
    await nav('Page shortcuts'); await shot('shortcuts');
    await page.context().grantPermissions(['clipboard-read', 'clipboard-write']);
    await nav('Copy Reports shortcut');
    const copied = await page.evaluate(() => navigator.clipboard.readText());
    if (copied !== 'tink://open?page=reports') throw new Error('Wrong page-only shortcut: ' + copied);
    await goBack(); await goBack();
  });

  await scenario('category-filter', async () => {
    // An excluded category must be absent from the ACTUAL exported full scope.
    await button('All tools').click(); await nav('Activity');
    await button('Filters').click();
    await revealText('Exclude categories (including children)', 206);
    const excluded = page.getByLabel('Excluded categories', {exact: true});
    const food = excluded.getByRole('button', {name: 'Food & Dining', exact: true})
      .or(excluded.getByText('Food & Dining', {exact: true})).or(excluded.getByLabel('Food & Dining', {exact: true})).first();
    await food.click(); await shot('filters');
    await nav('Apply filters');
    await button('Export filtered records').click(); await pause();
    const caption = page.getByText(/^Export \d+ transactions?/).or(page.getByLabel(/^Export \d+ transactions?/)).first();
    const captionText = await caption.evaluate(el => el.getAttribute('aria-label') || el.textContent || '');
    const count = Number(captionText.match(/^Export (\d+)/)?.[1]);
    if (!count) throw new Error('Exclusion test needs a nonempty remaining scope');
    const pendingCSV = page.waitForEvent('download', {timeout: 60000});
    await nav('CSV spreadsheet');
    const csv = await pendingCSV;
    const csvPath = path.resolve('review-shots', '2026-excluded.csv');
    await csv.saveAs(csvPath);
    const rows = csvRows(fs.readFileSync(csvPath, 'utf8').replace(/^\uFEFF/, ''));
    const categoryColumn = rows[0].indexOf('category');
    if (rows.length - 1 !== count || categoryColumn < 0 || rows.slice(1).some(row => row[categoryColumn] === 'Food & Dining')) {
      throw new Error('Category exclusions were lost in CSV export: declared=' + count + ', actual=' + (rows.length - 1) + ', categoryColumn=' + categoryColumn + ', sample=' + JSON.stringify(rows.slice(1, 5).map(row => [row[3], row[categoryColumn]])));
    }
    await goBack(); await goBack();
  });

  await scenario('keyboard-next', async () => {
    await button('Add transaction').click(); await pause();
    await input('What was it for?', 'Unsaved 2026 keyboard check');
    await page.keyboard.press('Enter'); await page.waitForTimeout(350);
    if (!/^Amount \(/.test(await focusedLabel())) throw new Error('Name Next did not focus Amount');
    await input(/^Amount \(/, '2+0.50');
    await page.keyboard.press('Enter'); await page.waitForTimeout(350);
    if (await focusedLabel() !== 'A little note (optional)') throw new Error('Amount Next did not focus Description');
    await input('A little note (optional)', 'A draft, not an automatic save');
    await page.keyboard.press('Tab'); await shot('entry-next');
    await goBack(); // Cancel the unsaved draft. No implicit save action was used.
  });

  await scenario('account-panes', async () => {
    await page.setViewportSize({width: 800, height: 1000}); await pause();
    await button('All tools').click(); await nav('Accounts');
    await visibleText('Pick an account').waitFor();
    await nav('Pocket money', true);
    await button('Close account panel').waitFor(); await shot('portrait-accounts');
    await page.setViewportSize({width: 1280, height: 900}); await shot('landscape-accounts');
    await button('Close account panel').click(); await visibleText('Pick an account').waitFor();
    await goBack(); await goBack();
    await page.setViewportSize({width: 390, height: 844}); await pause();
  });

  await scenario('legacy-import', async () => {
    await settings(); await nav('Backup & restore'); await nav('Import Paisa 6.3.6 JSON');
    const fixture = fs.readFileSync('test/fixtures/paisa_636.json');
    const chooser = page.waitForEvent('filechooser');
    await button('Choose legacy JSON · up to 10 MiB').click();
    await (await chooser).setFiles({name: 'Paisa-6.3.6.json', mimeType: 'application/json', buffer: fixture});
    await visibleText('Paisa-6.3.6.json').waitFor(); await shot('import-file');
    await input('New profile name', '2026 imported demo'); await page.keyboard.press('Tab');
    await nav('Original backup currency'); await nav('USD · \\$');
    await nav('Review legacy loan directions'); await nav('Debt = I borrowed · Credit = I lent');
    await nav('Validate & preview import');
    await revealText('Validated preview', 200); await shot('import-preview');
    await visibleText('2 accounts · 3 transactions').waitFor();
    await visibleText('2 loans · 1 goals · 3 history records').waitFor();
    await revealText('Read before importing', 200); await shot('import-notes');
    await nav('Create imported profile');
    await button('Cancel').click(); await pause(); // Preview/cancel does not import.
    await nav('Create imported profile'); await button('Create new profile').click();
    await visibleText('Your new profile is saved').waitFor(); await shot('import-saved');
    await goBack();
    await nav('Download retained original Paisa JSON');
    const pendingOriginal = page.waitForEvent('download', {timeout: 60000});
    await button('Export original JSON').click();
    const original = await pendingOriginal;
    if (original.suggestedFilename() !== 'Paisa-6.3.6-original.json') throw new Error('Wrong retained-original filename');
    const originalPath = path.resolve('review-shots', '2026-original.json');
    await original.saveAs(originalPath);
    if (!fs.readFileSync(originalPath).equals(fixture)) throw new Error('Retained original legacy JSON changed');
  });

  if (failures.length) throw new Error('2026 workflow failures:\n' + failures.join('\n\n'));
  console.log('::notice title=Tink 2026 browser workflows::PASS: inline Home move, fixed-shape privacy, copied page-only URL, category exclusion with actual CSV rows, real keyboard Next chain without save, portrait/landscape account panes, actual legacy file chooser, explicit currency/direction, preview/cancel/new-profile import, byte-identical retained-original download and isolated demo exit.');
};
