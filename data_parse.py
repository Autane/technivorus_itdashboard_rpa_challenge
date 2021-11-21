from bs4 import BeautifulSoup


def agency_spend(agency_data_html):
    soup = BeautifulSoup(agency_data_html, "html.parser")
    agencies = soup.find_all("div", class_="col-sm-12")
    agency_spend_list = []
    for tile in agencies:
        row = []
        dept = tile.find("span", class_="h4 w200").text
        row.append(dept)
        spend = tile.find("span", class_="h1 w900").text
        row.append(spend)
        agency_spend_list.append(row)
    return agency_spend_list


def investment_data(investment_data_html):
    soup = BeautifulSoup(investment_data_html, "html.parser")
    projects = soup.find_all("tr")
    project_spend_list = []
    for p in projects:
        row = []
        details = p.find_all("td")
        uii = details[0].text
        row.append(uii)
        link = p.find("a", href=True)
        try:
            uii_url = link['href']
        except:
            uii_url = ""
        row.append(uii_url)
        bureau = details[1].text
        row.append(bureau)
        investment_title = details[2].text
        row.append(investment_title)
        total_spending = details[3].text
        row.append(total_spending)
        type = details[4].text
        row.append(type)
        cio_rating = details[5].text
        row.append(cio_rating)
        no_of_projects = details[6].text
        row.append(no_of_projects)
        project_spend_list.append(row)
    return project_spend_list


def find_investment_name(first_page):
    investment_name_list = first_page.split("Name of this Investment: ")
    investment_name_list = investment_name_list[1].split("2.")
    investment_name = investment_name_list[0]
    investment_name = investment_name.replace("\n", " ")
    return investment_name, investment_name_list[1]


def find_uii(investment_name_list):
    uii_list = investment_name_list.split("Unique Investment Identifier (UII): ")
    uii_list = uii_list[1].split("Section")
    uii = uii_list[0]
    return uii
