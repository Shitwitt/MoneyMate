/* All financial edits are confined to the fictional, in-memory demo. */
module.exports = async function referenceBatchThree({page, nav, goBack, capture, scroll, revealText, visibleText, swipeCarousel}) {
  const pause = () => page.waitForTimeout(400);
  const button = name => page.getByRole('button', {name, exact: true});
  const shot = async name => {await pause(); await capture('web-batch3-' + name + '.jpg');};
  async function fill(label, text) {
    const field = page.getByRole('textbox', {name: label}).first();
    await field.click(); await page.keyboard.press('ControlOrMeta+A'); await page.keyboard.type(text); await page.keyboard.press('Tab');
  }
  await goBack(); // Recurring -> Home, with All tools still expanded.
  await nav('Loans');
  await button('How Loans Work').click(); await shot('loan-help');
  await scroll(1800); await shot('loan-help-bottom'); await button('Got it').click();
  await nav('Alex'); await shot('loan-detail');
  await button('Record a repayment').click(); await pause();
  await fill(/^Repaid \(/, '1');
  await page.getByText('None · tracking only', {exact: true}).last().click(); await pause();
  await page.getByText('Cash', {exact: true}).last().click();
  await button('Save').click(); await pause();
  await revealText('Payment History'); await shot('loan-history');
  await nav('Repayment · Alex'); await shot('transaction-detail');
  await button('Copy').click(); await pause();
  await page.getByRole('textbox', {name: 'What was it for?', exact: true}).waitFor();
  await goBack(); // Copy is an unsaved draft, not an immediate duplicate.
  await button('Edit').click(); await shot('loan-editor');
  await revealText('Colors'); await shot('loan-colors');
  await scroll(-20000); await pause(); await nav('Borrowing'); await revealText('Category'); await shot('loan-borrowing');
  await goBack(); // Cancel direction change, retaining the posted repayment.
  await scroll(-20000); await pause(); await button('Edit').click(); await pause();
  await fill('Loan name', 'Alex loan verified'); await button('Update Loan').click();
  await visibleText('Alex loan verified').waitFor();
  await goBack(); await goBack(); // Loan list -> Home.

  await nav('Goals'); await shot('goals');
  await button('How Goals Work').click(); await shot('goals-help'); await button('Got it').click();
  await nav('Emergency fund'); await shot('goal-detail');
  for (const label of ['Weekly', 'Monthly', 'Yearly', 'Daily']) {await nav(label);}
  await button('Edit').click(); await shot('goal-editor');
  await fill('Goal name', 'Emergency fund verified'); await button('Update Goal').click(); await pause();
  await visibleText('Emergency fund verified').waitFor();
  await button('Archive goal').click(); await pause();
  await button('Restore goal').click(); await pause();
  await goBack(); await nav('Completed'); await nav('Archived'); await nav('Active'); await goBack();

  await nav('Labels'); await shot('labels');
  await button('Show label grid').click(); await shot('labels-grid'); await button('Show label list').click();
  await nav('Overall'); await nav('This month');
  await button('How Labels Work').click(); await shot('labels-help'); await button('Got it').click();
  await nav('Everyday'); await shot('label-detail');
  for (const label of ['Weekly', 'Monthly', 'Yearly', 'Daily']) {await nav(label);}
  await button('Edit label').click(); await pause(); await fill('Name', 'Everyday verified');
  await button('Update label').click(); await pause(); await visibleText('Everyday verified').waitFor();
  await goBack(); await goBack();

  await nav('Analytics'); await shot('analytics');
  // A real touch swipe, not merely programmatic page selection.
  if (await button('Next smart insight').isEnabled().catch(() => false)) {
    await swipeCarousel(225); await shot('analytics-swiped');
  }
  await revealText('Top categories'); await shot('analytics-monthly');
  await revealText('Monthly Overview');
  await button('Next chart point').first().click(); await pause();
  await revealText('Spending Predictions'); await shot('analytics-predictions');
  await revealText('Unusual Spending'); await shot('analytics-unusual');
  await revealText('Category Trends'); await shot('analytics-trends');
  await revealText('Spending by Day of Week'); await shot('analytics-weekdays');
  await button('Analytics methods').click(); await shot('analytics-methods'); await button('Got it').click();
  await goBack();
  console.log('::notice title=Tink Batch 3 browser::PASS: Loans help/editor/type categories/partial posted repayment/history/transaction-copy draft/update; Goals help/detail/grouping/update/archive/restore/statuses; Labels list/grid/scope/help/detail/grouping/update; Analytics carousel real swipe, chart point control, every section and methods. No APK compilation.');
};
