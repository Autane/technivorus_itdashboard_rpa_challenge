*** Settings ***
Documentation   IT dashboard RPA challenge
Library      RPA.Browser.Playwright
Library      RPA.Excel.Files
Library      RPA.FileSystem
Library      RPA.PDF
Library      data_parse


*** Keywords ***
Save Agency Budgets to Excel
    Create Directory    ${CURDIR}\\output
    ${agency_data_html}    Get Property  //div[@id='agency-tiles-container']  property=outerHTML
    Log    ${agency_data_html}
    ${rows}    agency_spend  ${agency_data_html}
    Log   ${rows} 
    Create Workbook    fmt=xlsx
    Create Worksheet    Agency_Spend
    Append Rows To Worksheet    ${rows}  Agency_Spend
    Save Workbook    ${CURDIR}\\output\\agencies.xlsx
    # Choose US Department of Commerce
    Click    //div[@id='agency-tiles-container']//*[@alt="Seal of the Department of Commerce"]

*** Keywords***
Save Investments Table
    Select Options By    //select[@name='investments-table-object_length']  value  -1
    FOR    ${i}    IN RANGE  180
        ${page2_exists}    Get Element State    //a[.='2']
        Exit For Loop If    ${page2_exists}==False
        Sleep    1s
    END
    ${investment_data_html}    Get Property  //div[@id="investments-table-container"]//tbody  property=outerHTML
    Log    ${investment_data_html}
    ${rows}    investment_data  ${investment_data_html}
    Log    ${rows}
    Open Workbook    ${CURDIR}\\output\\agencies.xlsx
    Create Worksheet    IT_projects
    Append Rows To Worksheet    ${rows}  IT_projects
    Save Workbook    ${CURDIR}\\output\\agencies.xlsx
    [Return]    ${rows}

*** Keywords ***
Compare Values from PDF with Table
    [Arguments]    ${it_projects}
    FOR    ${project}  IN  @{it_projects}
        IF  "${project}[1]"!=""
            Go To    https://itdashboard.gov${project}[1]
            Wait For Elements State  //a[.='Download Business Case PDF']
            # Set download path
            ${dl_promise}  Promise To Wait For Download  ${CURDIR}\\output\\${project}[0].pdf
            Click    //a[.='Download Business Case PDF']
            ${file_obj}    Wait For  ${dl_promise}
            # PDF - conduct checks and log
            ${text}    Get Text From PDF    ${CURDIR}\\output\\${project}[0].pdf
            # Find investment_name and Compare
            ${first_page}    Set Variable  ${text[1]}
            Log    ${first_page}
            ${investment_name}  ${investment_name_list}    find_investment_name  ${first_page}
            ${investment_titles_compare}    Run Keyword and Return Status  
            ...    Should Be Equal  ${investment_name}  ${project}[3]
            # Find UII and Compare
            ${uii}    find_uii  ${investment_name_list}
            ${uii_compare}    Run Keyword and Return Status  
            ...    Should Be Equal  ${uii}  ${project}[0]
        END
    END

*** Tasks ***
Extract data from IT dashboard
    New Browser    chromium    headless=true
    New Context    acceptDownloads=True
    Set Browser Timeout    30
    Eat All Cookies
    New Page    https://itdashboard.gov/
    Wait For Elements State  //a[contains(text(),'DIVE IN')]
    Click    //a[contains(text(),'DIVE IN')]
    Wait For Elements State  //div[@id='agency-tiles-container']
    Save Agency Budgets to Excel 
    Wait For Elements State    //table[@id="investments-table-object"]
    ${agency_name}    Get Text  //h1[@class='h4 w200 agencyName']
    Log    ${agency_name}
    ${it_projects}    Save Investments Table
    Compare Values from PDF with Table  ${it_projects}
