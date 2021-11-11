# -*- coding: utf-8 -*-
"""
Created on Wed Nov  3 18:12:50 2021

@author: Victor Borrayo
"""

import streamlit as st
import numpy as np
import pandas as pd


st.title("This is my first app, for Galileo Master")

x= 4

st.write(x, 'square is', x**2)

x, 'square is', x**2

"""
## Data Frames
"""

df = pd.DataFrame({
    'Column A' : [1,2,3,4,5],
    'Column B' : ['A','B','C','D','E']
    
    })

st.write(df)

"""
# Titulo
## Subtitulo 1

"""

df



"""
## Let's use some graphics



"""

chart_df = pd.DataFrame(np.random.randn(20,3), columns = ['A','B', 'C'])

st.line_chart(chart_df)


"""
## How about a map
"""

map_df = pd.DataFrame(
    np.random.randn(1000,2)/[50,50] + [37.76,-122.4],
    columns=['lat','lon']
    )

st.map(map_df)


"""
## Show me some widgets

"""

"""
## Checkbox

"""

if st.checkbox('Show me the dataframe'):
    map_df


"""
### Slider test

"""

x = st.slider('Select value for X')

st.write(x, 'squere is ', x**2)

"""
### Option
"""

option = st.selectbox(
    'Wich number do you like best?',
    [1,2,3,4,5,6,7,8,9,10]
    )

'you select the option', option



"""
### Progressbar
"""
import time

progress_bar_label = st.empty()
progress_bar = st.progress(0)
progress_bar_2 = st.sidebar.progress(0)

for i in range(101):
    progress_bar_label.text('Iteration{}'.format(i))
    progress_bar.progress(i)
    time.sleep(0.01)



for i in range(101):
    progress_bar_2.progress(i)
    time.sleep(0.01)



option_side = st.sidebar.selectbox('Chose your weapon?', ['handung', 'machinegun', 'knife'])
st.sidebar.write('Your choice is:', option_side)

another_slider = st.sidebar.slider('Select the Range', 0.0,100.0,(25.0,75.0))

st.sidebar.write('The range selected is', another_slider)




























