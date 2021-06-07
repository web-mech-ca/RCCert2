# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.RobotLogListener
Library           RPA.FileSystem
Library           Collections
Library           RPA.Robocloud.Secrets
Library           RPA.Archive

# -


*** Variables ***
@{MODEL_INFO}=    0    Roll-a-thor    Peanut crusher    D.A.V.E	   Andy Roid    Spanner mate    Drillbit 2000
${MAX_ATTEMPTS}=    5


*** Keywords ***
Download The CSV File
    ${urls}=    Get Secret    urls
    Download    ${urls}[csv_url]    overwrite=Tru


*** Keywords ***
Open the robot order website
    ${urls}=    Get Secret    urls
    Open Available Browser     ${urls}[order_url]


*** Keywords ***
Get orders
    Download The CSV File
    ${orders}=    Read table from CSV    orders.csv
    Log    Found columns: ${orders.columns}
    [return]    ${orders}

*** Keywords ***
Close the annoying modal
    ${found}=     Run keyword And Return Status    Wait Until Page Contains Element    class:modal-content    timeout=3    error=false
    IF    ${found}
        Log    Found Modal!
        Click Button    OK
    END

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    # Log    OrdNum> ${row}[Order number] Head> ${MODEL_INFO}[${row}[Head]] Body> ${MODEL_INFO}[${row}[Body]] Legs> ${MODEL_INFO}[${row}[Legs]]
    Select From List By Value        id:head             ${row}[Head]
    #Select Radio Button              body                ${MODEL_INFO}[${row}[Body]] body
    Click Button                     id:id-body-${row}[Body]
    Input Text                       xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text                       id:address          ${row}[Address]


*** Keywords ***
Preview the robot
    Click Button                     id:preview
    FOR    ${i}    IN RANGE    ${MAX_ATTEMPTS}
        ${found}=     Run keyword And Return Status    Wait Until Element Is Visible    id:robot-preview-image
        IF     ${found} == True
            Exit For Loop If    True
        ELSE
            Click Button                     id:preview
            # Wait Until Element Is Visible    id:robot-preview-image
        END
    END

*** Keywords ***
Submit the order
    Click Button                     id:order
    FOR    ${i}    IN RANGE    ${MAX_ATTEMPTS}
        ${found}=     Run keyword And Return Status    Wait Until Element Is Visible    id:receipt
        IF     ${found} == True
            Exit For Loop If    True
        ELSE
            Click Button                     id:order
            # Wait Until Element Is Visible    id:receipt
        END
    END 

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order_num}
    ${sales_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_receipt_html}    ${CURDIR}${/}output${/}recipt_${order_num}.pdf
    [return]    ${CURDIR}${/}output${/}recipt_${order_num}.pdf


*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${order_num}
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}rbt_view_${order_num}.png
    [return]    ${CURDIR}${/}output${/}rbt_view_${order_num}.png


*** Keywords ***
Embed the robot screenshot to the receipt PDF file    
    [Arguments]    ${screenshot}    ${pdf}
    #@{files}=     Create List    ${screenshot}:x=25,y=100
    #Add Files To PDF    ${files}    ${pdf}    append-true
    Add Watermark Image To PDF    image_path=${screenshot}    source_path=${pdf}    output_path=${pdf}    coverage=0.2
    Close Pdf    ${pdf}

*** Keywords ***
Go to order another robot
    Click Button                     id:order-another

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip  ${CURDIR}${/}output      ${CURDIR}${/}output${/}receipts.zip   include=*.pdf


*** Keywords ***
Close The Browser
    Close Browser

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders}=    Get orders
    Open the robot order website
    FOR    ${row}    IN    @{orders}
         Close the annoying modal
         Fill the form    ${row}
         Preview the robot
         Submit the order
         ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
         ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
         Go to order another robot
    END
    Create a ZIP file of the receipts
    Close The Browser


