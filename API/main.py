from fastapi import FastAPI, APIRouter
from scheduling import router as schedule_router

app= FastAPI()
app.include_router(schedule_router)


