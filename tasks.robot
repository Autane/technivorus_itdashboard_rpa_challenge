*** Settings ***
Documentation   IT dashboard RPA challenge
Library      RPA.Browser.Playwright
Library      RPA.Excel.Files
Library      RPA.FileSystem
Library      RPA.PDF
Library      Collections
Library      String


*** Keywords ***
Save Agency Budgets to Excel
    ${agency_data}   Get Elements   //div[@id='agency-tiles-container']//div[@class='col-sm-12']
    Log    ${agency_data}
    ${rows}    Create List
    Create Directory    ${CURDIR}\\output
    FOR  ${i}  IN  @{agency_data}
        ${dept}    Get Text  ${i} >> //span[@class='h4 w200']
        ${spend}    Get Text  ${i} >> //span[@class=' h1 w900']
        ${row}    Create List  ${dept}  ${spend}
        Append To List    ${rows}  ${row}
    END
    Create Workbook    fmt=xlsx
    Create Worksheet    Agency_Spend
    Append Rows To Worksheet    ${rows}  Agency_Spend
    Save Workbook    ${CURDIR}\\output\\agencies.xlsx
    # Choose US Department of Commerce
    Click    ${agency_data}[1]

*** Keywords***
Save Investments Table
    Select Options By    //select[@name='investments-table-object_length']  value  -1
    FOR    ${i}    IN RANGE  180
        ${page2_exists}    Get Element State    //a[.='2']
        Exit For Loop If    ${page2_exists}==False
        Sleep    1s
    END
    ${investment_data}    Get Elements   //div[@id="investments-table-container"]//tbody//tr
    Log    ${investment_data}
    ${rows}    Create List
    FOR  ${i}  IN  @{investment_data}
        ${UII}    Get Text  ${i} >> //td[1]
        ${UII_link_exists}    Get Element State  ${i} >> //td[1]//a
        IF  ${UII_link_exists}  
            ${UII_url}    Get Attribute   ${i} >> //td[1]//a  href
        ELSE
             ${UII_url}    Set Variable 
        END
        ${Bureau}    Get Text  ${i} >> //td[2]
        ${Investment_Title}    Get Text  ${i} >> //td[3]
        ${Total_Spending}    Get Text  ${i} >> //td[4]
        ${Type}    Get Text  ${i} >> //td[5]
        ${CIO_Rating}    Get Text  ${i} >> //td[6]
        ${Number_Of_Projects}    Get Text  ${i} >> //td[7]
        ${row}    Create List  ${UII}  ${UII_url}  ${Bureau}  ${Investment_Title}  ${Total_Spending}  ${Type}  ${CIO_Rating}  ${Number_Of_Projects}
        Log  ${row}
        Append To List    ${rows}  ${row}
    END
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
            ${investment_name_list}    Split String  ${first_page}  Name of this Investment:${space}
            ${investment_name_list}    Split String  ${investment_name_list}[1]   2. 
            ${investment_name}    Set Variable  ${investment_name_list}[0]
            ${investment_name}    Replace String  ${investment_name}  \n  ${space}   
            ${investment_titles_compare}    Run Keyword and Return Status  
            ...    Should Be Equal  ${investment_name}  ${project}[3]
            # Find UII and Compare
            ${uii_list}    Split String  ${investment_name_list}[1]  Unique Investment Identifier (UII):${space}
            ${uii_list}    Split String  ${uii_list}[1]  Section
            ${uii}    Set Variable  ${uii_list}[0]
            ${uii_compare}    Run Keyword and Return Status  
            ...    Should Be Equal  ${uii}  ${project}[0]
        END
    END

*** Tasks ***
Extract data from IT dashboard
    New Browser    chromium    headless=false
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
