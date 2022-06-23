import csv
import requests
import json


def get_json():
    url = "https://www.ozon.ru/api/composer-api.bx/page/json/v2" \
          "?url=/product/avtomaticheskaya-kofemashina-inhouse-rozhkovaya-coffee-arte-icm1507-seryy-397529235/"
    response = requests.get(url=url)
    with open('ozon_1.json', 'w', encoding='utf-8') as file:
        json.dump(response.json(), file, ensure_ascii=False)

    return response.json()


def get_product_info(result):
    product = {}
    widgets = result["widgetStates"]
    for widget_name, widget_value in widgets.items():
        widget_value = json.loads(widget_value)
        if "webSale" in widget_name:
            product_info = widget_value["cellTrackingInfo"]["product"]
            product["title"] = product_info["title"]
            product["id"] = product_info["id"]
            product["price"] = product_info["price"]
            product["final_price"] = product_info["finalPrice"]

    with open('ozon.csv', 'a', encoding='utf-8') as filecsv:
        csv.DictWriter(filecsv, fieldnames=["title", "id", "price", "final_price"]).writerow(product)


def main():
    get_json()
    with open('ozon.csv', 'w', encoding='utf-8') as filecsv:
        csv.DictWriter(filecsv, fieldnames=["title", "id", "price", "final_price"]).writeheader()

    with open('ozon_1.json', 'r', encoding='utf-8') as file:
        result = json.load(file)
        get_product_info(result)


if __name__ == '__main__':
    main()