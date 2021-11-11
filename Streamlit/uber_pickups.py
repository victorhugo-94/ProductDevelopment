# -*- coding: utf-8 -*-
"""
Created on Wed Nov  3 19:50:07 2021

@author: Victor Borrayo
"""

import streamlit as st
import numpy as np
import pandas as pd
import math

st.write("Uber pickups test")

source = "https://s3-us-west-2.amazonaws.com/streamlit-demo-data/uber-raw-data-sep14.csv.gz"



@st.cache
def download_data():
    return (pd.read_csv(source).rename(columns={'Lat':'lat','Lon':'lon'}))




df = download_data()

page_size = 1000
total_pages= math.ceil(len(df)/page_size)
starting_value = 0


slider = st.slider('Select the page', 1,total_pages)

st.write('page selected', slider, 'with limits', (((slider-1)*page_size),(slider*page_size)-1))



tdf = df.loc[((slider-1)*page_size):(slider*page_size)-1]

tdf

st.map(tdf)


st.write("Ejercicio")

hour_slider = st.slider('Seleccione intervalo de hora', 0,24,(0,24),1)
st.write("Rango de horas seleccionado:", hour_slider)

#tdf2 = df.iloc[0:100]

tdf2 = df[:]
tdf2["hour"] = pd.to_datetime(tdf2["Date/Time"], format = '%m/%d/%Y %H:%M:%S').dt.hour
#tdf2["hour"] = tdf2["hour"].hour

tdf2 = tdf2[tdf2["hour"].between(hour_slider[0], hour_slider[1])]
tdf2.reset_index(inplace = True)

page_size2 = 1000
total_pages2= math.ceil(len(tdf2)/page_size2)
starting_value = 0

slider2 = st.slider('Seleccione página', 1,total_pages2)

tdf3 = tdf2.loc[((slider2-1)*page_size2):(slider2*page_size2)-1]
tdf3

st.map(tdf3)

#st.bar_chart(tdf2.groupby(['hour']).sum())

tdf4 = tdf2.groupby(['hour']).count()
#tdf4['hora'] = tdf4.index
tdf4['pickups'] = tdf4['Date/Time']

st.bar_chart(tdf4['pickups'])



