*** Settings ***
Library    Collections
Library    OperatingSystem
Library    Process
Library    String

*** Variables ***
${BINARY_PATH}          /path/to/the/test/binary
${CONFIG_FILE_DIR}      /path/to/the/config/file/dir

*** Test Cases ***
Test Files
    FOR  ${i}  IN RANGE  1  5
      Run Configuration File  ${CONFIG_FILE_DIR}/options-test${i}.cfg
    END


*** Keywords ***
Run Configuration File
    [Arguments]  ${file_path}
    # Read the configuration file
    ${file_content}=    Get File    ${file_path}
    # Extract and set environment variables from the ENV block
    ${env_block}=    Get Block From File    ${file_content}    BEGIN ENV    END ENV
    Set Environment Variables    ${env_block}
    # Extract CLI arguments from the CLI block
    ${cli_args}=    Get Block From File    ${file_content}    BEGIN CLI    END CLI
    Append To List  ${cli_args}  --config-file  ${file_path}
    # Run the program with arguments
    ${output}=    Run Process    ${BINARY_PATH}    @{cli_args}
    Log    Program Output: ${output.stdout}
    # Extract the BASELINE block
    ${baseline_block}=    Get Block From File    ${file_content}    BEGIN BASELINE    END BASELINE
    ${baseline}=          Catenate  SEPARATOR=\n  @{baseline_block}
    # Compare the program output with the BASELINE block
    ${app_output}=        Strip String   ${output.stdout}
    Should Be Equal As Strings    ${app_output}    ${baseline}

Get Block From File
    [Arguments]  ${file_content}    ${begin_marker}    ${end_marker}
    ${lines}=    Split To Lines    ${file_content}
    ${begin}=    Evaluate  ${lines}.index("# ${begin_marker}") + 1
    ${end}=      Evaluate  ${lines}.index("# ${end_marker}")
    ${block}=    Get Slice From List  ${lines}    ${begin}    ${end}
    ${result}=   Evaluate    [line[2:] for line in ${block}]
    [Return]     ${result}

Set Environment Variables
    [Arguments]    ${lines}
    FOR    ${line}    IN    @{lines}
       ${parts}=    Evaluate    "${line}".split("=")
       Set Environment Variable    ${parts[0].strip()}    ${parts[1].strip()}
    END

