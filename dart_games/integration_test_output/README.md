# UI Automation Test Results

This folder contains the output from UI automation tests run via `run_ui_tests.bat`.

## Running the Tests

Simply run the test script:

```bash
run_ui_tests.bat
```

The script will automatically:
1. Stop any existing ChromeDriver instances
2. Start ChromeDriver on port 4444
3. Run all UI automation tests sequentially
4. Stop ChromeDriver when tests complete

**No manual ChromeDriver setup required!**

## Test Results

The script runs 6 test files containing 76 total tests (~43 minutes):

1. **01_target_tag_menu_and_mechanics.log** - 23 tests (~12 min)
2. **02_target_tag_visual_validation.log** - 4 tests (~2 min)
3. **03_target_tag_gameplay.log** - 13 tests (~10 min)
4. **04_target_tag_add_player.log** - 6 tests (~2 min)
5. **05_target_tag_results_screen.log** - 6 tests (~5.5 min)
6. **06_carnival_derby_ui.log** - 24 tests (~12 min)

## Output Files

- **summary.txt** - Overall test suite summary (pass/fail counts, timing)
- **XX_test_name.log** - Detailed output for each test file (includes start/end times and full test output)

## Interpreting Results

Each log file contains:
- Start/end timestamps
- Full Flutter driver output
- PASSED or FAILED status at the end

Check `summary.txt` for a quick overview of which tests passed or failed.

## Troubleshooting

**"ChromeDriver not found at chromedriver\chromedriver-win64\chromedriver.exe"**
- Download ChromeDriver from https://chromedriver.chromium.org/downloads
- Extract to `chromedriver\chromedriver-win64\` folder
- Ensure the version matches your Chrome browser version

**"ChromeDriver failed to start on port 4444"**
- Check if Chrome browser is installed
- Verify port 4444 is not blocked by firewall
- Try running `chromedriver\chromedriver-win64\chromedriver.exe` manually to see error messages

**Tests hang or timeout**
- Check ChromeDriver version matches your Chrome browser version
- Close Chrome browser and retry

**All tests fail**
- Ensure you're in the dart_games directory when running the script
- Check that integration_test files exist
- Verify test_driver/integration_test.dart exists
