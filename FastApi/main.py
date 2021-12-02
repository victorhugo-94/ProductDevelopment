# -*- coding: utf-8 -*-
"""
Created on Wed Nov 24 18:37:25 2021

@author: vborrayo
"""

from fastapi import FastAPI
from typing import Dict, Optional
from enum import Enum

app = FastAPI()


class RoleName(str, Enum):
    admin = 'Admin'
    writer = 'Writer'
    reader = 'Reader'



@app.get("/")
def root():
    return {"message":"Hello Word, from Galileo Master!!! Section V"}


@app.get("/items/{item_id}")
def read_item(item_id: int) -> Dict[str, int]:
    return {"item_id": item_id}




@app.get("/users/me")
def read_current_user():
    return {"user_id":"currentUser"}






@app.get("/users/{user_id}")
def read_user(user_id: str):
    return {"user_id": user_id}



@app.get("/roles/{role_name}")
def get_role_permissions(role_name: RoleName):
    #return role permissions
    if role_name == RoleName.admin:
        return {"role_name" : role_name, "permissions" : "Full acess"}

    if role_name == RoleName.writer:
        return {"role_name" : role_name, "permissions" : "Write"}
    
    return {"role_name" : role_name, "permissions" : "Read access only"}




fake_items_db = [{"item_name" : "uno"}, {"item_name" : "dos"}, {"item_name" : "tres"}]


# @app.get("/items/")
# def read_items(skip: int = 0, limit: int = 10):
#     return fake_items_db[skip: skip + limit]


@app.get("/items/")
def read_item_query(item_id: int, query: Optional[str] = None):
    message = {'item_id' : item_id}
    if query:
        message['query'] = query
        
    return message

@app.get("/User/{user_id}/items/{item_id}")
def read_user_item(user_id: int, item_id: int, query: Optional[str] = None, describe: bool = False):
    item = {"item_id": item_id, "owner_id": user_id}
    if query:
        item['query'] = query()
    
    if not describe:
        item['description'] = "This is a long description for the item"

    return item



from pydantic import BaseModel


class Item(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    tax: Optional[float] = None



@app.post("/items/")
def create_item(item: Item):
    return {
            "message": "The item was succesfully created",
            "item": item.dict()
        }
    
    
@app.put("/items/{item_id}")
def update_item(item_id: int,item: Item):
    if item.tax == 0 or item.tax is None:
        item.tax = item.price * 0.12
    return{
        "message" : "the item was updated",
        "item_id" : item_id,
        "item" : item.dict()
        }
    


from fastapi.responses import ORJSONResponse, HTMLResponse, StreamingResponse


@app.get("/itemsall", response_class = ORJSONResponse)
def read_long_json():
    return [{"item_id": "item"}, {"item_id": "item"}, {"item_id": "item"},
            {"item_id": "item"}, {"item_id": "item"}, {"item_id": "item"},
            {"item_id": "item"}, {"item_id": "item"}, {"item_id": "item"}]



# @app.get("/html")
# def read_html():
    
import io
import pandas as pd

# @app.get("/csv")
# def get_csv():
#     df = pd.DataFrame({"Column A":[1,2], "Cjolumn B": [3,4]})
#     stream = io.StringIO()
    
#     df.to_csv(stream, index = False)
    
#     response = StreamingResponse(iter([stream.getvalue()]), media_type = 'text/csv')
#     response.headers['Content-Disposition'] = "attachment; filename = my_awsome_report.csv"
#     return response
    

@app.get("/csv")
def get_csv():
    df = pd.DataFrame({"Column A": [1, 2], "Column B": [3, 4]})

    stream = io.StringIO()

    df.to_csv(stream, index=False)

    response = StreamingResponse(iter([stream.getvalue()]), media_type='text/csv')

    response.headers['Content-Disposition'] = "attachment; filename=my_awesome_report.csv"

    return response


#Tarea

#Operaciones con get

@app.get("/get/sum{a}_{b}")
def get_sum(a: float, b: float):
    return {
        'sum' : a+b
        }

@app.get("/get/diff{a}_{b}")
def get_diff(a: float, b: float):
    return {
        'diff' : a-b
        }

@app.get("/get/mult{a}_{b}")
def get_mult(a: float, b: float):
    return {
        'mult' : a*b
        }


@app.get("/get/div{a}_{b}")
def get_div(a: float, b: float):
    try:
        return {
            'div' : a/b
            }

    except ZeroDivisionError:
        return {
            'msj' : 'División entre 0 no permitida.'
            }


#Operaciones con post


@app.post("/post/sum{a}_{b}")
def get_sum(a: float, b: float):
    return {
        'sum' : a+b
        }

@app.post("/post/diff{a}_{b}")
def get_diff(a: float, b: float):
    return {
        'diff' : a-b
        }

@app.post("/post/mult{a}_{b}")
def get_mult(a: float, b: float):
    return {
        'mult' : a*b
        }


@app.post("/post/div{a}_{b}")
def get_div(a: float, b: float):
    try:
        return {
            'div' : a/b
            }

    except ZeroDivisionError:
        return {
            'msj' : 'División entre 0 no permitida.'
            }
























