/* Only the isolated, fictional demo may be edited by this journey. */
module.exports = async function referenceBatchFour({page, nav, goBack, capture, scroll, revealText, visibleText, swipeCarousel}) {
  const button = name => page.getByRole('button', {name, exact: true});
  const pause = async () => {await page.mouse.move(1,843); await page.waitForTimeout(400);};
  const shot = async name => {await pause(); await capture('web-batch4-' + name + '.jpg');};
  const counter = async (index, count) => {
    const pattern = new RegExp('^' + index + ' / ' + count + '$');
    await page.getByRole('group', {name: pattern}).or(page.getByText(pattern)).first().waitFor();
  };
  async function fill(label, text) {
    const field = page.getByRole('textbox', {name: label}).first();
    await field.click(); await pause();
    await page.keyboard.press('ControlOrMeta+A'); await page.keyboard.press('Backspace');
    await page.keyboard.type(text, {delay: 30});
    if (await field.inputValue() !== text) throw new Error('Batch 4 draft was not received intact: ' + label);
    await page.keyboard.press('Tab'); await pause();
  }
  async function hold(target, fraction = 0.5) {
    await target.waitFor();
    const box = await target.boundingBox();
    if (!box || box.width < 40 || box.height < 20) throw new Error('No inspectable painted panel');
    const x = box.x + Math.min(box.width - 10, 42 + (box.width - 48) * fraction);
    const y = box.y + Math.min(box.height / 2, 100);
    await page.mouse.move(x,y); await page.mouse.down();
    await page.waitForTimeout(700); await page.mouse.up(); await pause();
  }

  // These views are already exercised for real process/archive/history in the
  // preserved Batch 2 journey. Capture the exact latest Batch 4 presentation.
  await nav('Recurring'); await shot('recurring');
  await nav('Calendar'); await shot('recurring-calendar');
  await button('How recurring works').click(); await shot('recurring-help');
  await scroll(1800); await shot('recurring-help-bottom'); await button('Got it').click();
  await goBack();

  await nav('Categories'); await shot('categories');
  await button('How Categories Work').click(); await shot('categories-help'); await button('Got it').click();
  for (const type of ['Income','Transfer','Expense']) await nav(type);
  await nav('Food & Dining'); await shot('category-breakdown');
  await button('Show category donut').click(); await pause();
  await button('Next allocation segment').click(); await shot('category-donut');
  await button('Show stacked category breakdown').click();
  await revealText('Monthly Spending Trend'); await shot('category-monthly');
  const monthly = page.getByLabel('Recorded spending line chart', {exact: true});
  await hold(monthly, 0.98);
  await button('See matching records').waitFor(); await shot('category-hold');
  await button('See matching records').click(); await pause();
  await button('Filters').waitFor(); // A genuine scoped transaction route.
  await goBack();
  await button('Weekly category bars').click();
  await revealText('Recent Weekly Spending'); await shot('category-weekly');
  await hold(page.getByLabel('Recorded spending bar chart', {exact: true}), 0.94);
  await button('See matching records').waitFor();
  await revealText('Overview'); await shot('category-overview');
  await nav('Overall'); await nav('This month');
  await revealText('Transaction Insights'); await shot('category-insights');

  // Full-page entry, pinned save, template picker and arithmetic are genuine.
  await button('Add category transaction').click(); await pause();
  await button('Templates').click(); await nav('Coffee break');
  await fill('What was it for?', 'Batch four coffee verified');
  await fill(/^Amount \(/, '2+0.50');
  await fill('A little note (optional)', 'A local ledger note');
  await scroll(-20000); await shot('transaction-main');
  await button('Calculator').click(); await shot('transaction-calculator');
  await button('Calculator').click();
  await revealText('Category', 206); await shot('transaction-links');
  await revealText('People / payee', 206); await shot('transaction-context');
  await button('Collapse extra fields').click(); await scroll(-20000); await shot('transaction-collapsed');
  await button('Add transaction').click(); await pause();
  const celebration = button('A little proud of myself');
  if (await celebration.isVisible()) {await celebration.click(); await pause();}
  await revealText('Batch four coffee verified'); await shot('transaction-saved');
  await visibleText('Batch four coffee verified').waitFor();
  await goBack(); await goBack();

  await nav('Places'); await shot('places');
  await button('Show place grid').click(); await shot('places-grid'); await button('Show place list').click();
  await nav('Overall'); await nav('This month');
  await button('How Places Work').click(); await shot('places-help'); await button('Got it').click();
  await nav('Neighbourhood'); await shot('place-detail');
  await page.getByRole('button', {name: /^Edit place(?:\s|$)/}).click(); await pause();
  await fill('Name', 'Neighbourhood verified'); await button('Update place').click(); await pause();
  await visibleText('Neighbourhood verified').waitFor();
  await goBack(); await goBack();

  await nav('People'); await shot('people');
  await button('How People Work').click(); await shot('people-help'); await button('Got it').click();
  await nav('Alex'); await shot('person-detail');
  for (const period of ['Weekly','Monthly','Yearly','Daily']) await nav(period);
  await goBack(); await goBack();

  await nav('Spending Health'); await shot('health-index');
  await revealText('Expense-record streak'); await shot('health-streak');
  await revealText('Monthly Challenge'); await shot('health-challenge');
  await revealText('Monthly Report Card'); await shot('health-report');
  await revealText('Spending Habits'); await shot('health-habits');
  const heading = await visibleText('Spending Habits').boundingBox();
  const band = await button('Exit Demo').boundingBox();
  if (!heading) throw new Error('Spending habits heading missing');
  await swipeCarousel(heading.y + 145 - (band ? band.y + band.height + 4 : 0));
  await counter(2,3); await shot('health-habits-swiped');
  await revealText('Spending Heatmap'); await shot('health-heatmap');
  await button('Previous review month').click(); await button('Next review month').click();
  const today = new Date();
  const date = new Intl.DateTimeFormat('en-US', {year:'numeric',month:'long',day:'numeric',timeZone:'UTC'}).format(today);
  const escape = value => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const day = page.getByLabel(new RegExp('^' + escape(date) + '\\. \\d+ records\\.')).first();
  await hold(day);
  await visibleText('Transfers and excluded accounts omitted.').waitFor(); await shot('health-hold');
  await button('Close information').click();
  await revealText('Category Review'); await shot('health-categories');
  await revealText('Savings Projection'); await shot('health-projection');
  await hold(page.getByLabel('Recorded surplus line chart', {exact: true}), 0.8);
  await visibleText('Change versus previous point:').waitFor();
  await revealText('Possible Monthly Repeats'); await shot('health-repeats');
  await visibleText('Reading circle · demo').waitFor();
  await button('Review a monthly reminder draft').first().click(); await pause();
  await visibleText('Review recurring draft').waitFor(); await shot('health-reminder-draft');
  await button('Cancel editor').click(); await pause();
  await visibleText('Possible Monthly Repeats').waitFor();
  await button('Spending review methods').click(); await shot('health-methods'); await button('Got it').click();
  await goBack();
  console.log('::notice title=Tink Batch 4 browser::PASS: recurring list/calendar/help, category hierarchy/allocation/donut/monthly/weekly/hold/scoped records/overview/history, template/calculator/pinned transaction save with metadata, place list/grid/scope/help/persisted rename, people help/detail/grouping, local planning index/methods/streak/challenge/report, real habits swipe, heatmap hold values, category sparks, signed projection and unsaved monthly-reminder draft cancellation. Fictional demo only; no native build.');
};
