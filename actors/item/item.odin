package item

import "core:encoding/json"

Item :: struct {
	name: string,
	desc: string `json:"description"`,
	icon: string,
	dmg:  f32 `json:"damage"`,
}

item_dictionary : map[string]Item

load_items :: proc() {

	item_dictionary = make(map[string]Item)

	//test_item.json
	test_item := make([dynamic]Item, 0)
	defer delete(test_item)
	json.unmarshal(#load("test_item.json"), &test_item)
	item_dictionary["test_item[0]"] = test_item[0]
	item_dictionary["test_item[1]"] = test_item[1]
	item_dictionary["test_item[2]"] = test_item[2]
}

unload_items :: proc() {
	for _, i in &item_dictionary {
		delete_string(i.name)
		delete_string(i.desc)
		delete_string(i.icon)
	}
	delete(item_dictionary)
}
