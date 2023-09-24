from typing import Union
from pydantic import BaseModel
from datetime import datetime

from fastapi import FastAPI, UploadFile, File
from fastapi.staticfiles import StaticFiles

from detect import detect_image

app = FastAPI()

app.mount("/assets", StaticFiles(directory="assets"), name="static")

slots = [0,1,2,3,4,5,6,7,8]


@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: Union[str, None] = None):
    return {"item_id": item_id, "q": q}

@app.post("/detect")
async def detect_plate(file: UploadFile=File(...)):
    image_data = await file.read()
    res = detect_image(image_data)
    return {"number": res[0], "file_path": res[1]}

database = {}
checked_in_users = {}

class CheckInRequest(BaseModel):
    number_plate: str
    phone_number: str

class CheckOutResponse(BaseModel):
    number_plate: str
    phone_number: str
    check_in_time: datetime
    check_out_time: datetime
    price: float
    type: str = 'checkOut'

@app.post("/checkinout/")
async def check_in_out(request: CheckInRequest):
    number_plate = request.number_plate
    phone_number = request.phone_number

    if number_plate in checked_in_users:
        # User is already checked in, perform check-out
        check_in_time = checked_in_users.pop(number_plate)
        check_out_time = datetime.utcnow()
        
        # Calculate the duration in hours
        duration_hours = (check_out_time - check_in_time).total_seconds() / 3600

        # Calculate the price based on 50 Rs per hour
        price = duration_hours * 50

        return CheckOutResponse(
            number_plate=number_plate,
            phone_number=phone_number,
            check_in_time=check_in_time,
            check_out_time=check_out_time,
            price=price
        )
    else:
        # User is not checked in, perform check-in
        checked_in_users[number_plate] = datetime.utcnow()
        return {"type": "checkIn","message": f"Checked in for {number_plate}"}
