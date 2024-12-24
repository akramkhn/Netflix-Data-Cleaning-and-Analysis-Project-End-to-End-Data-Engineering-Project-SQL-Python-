#!/usr/bin/env python
# coding: utf-8

# In[17]:


get_ipython().system('pip install kaggle')


# In[22]:


import kaggle


# In[23]:


#download dataset using kaggle api
get_ipython().system('kaggle datasets download shivamb/netflix-shows -f netflix_titles.csv')


# In[27]:


# extract file for zip file
import zipfile
zip_ref = zipfile.ZipFile('netflix_titles.csv.zip')
zip_ref.extractall()
zip_ref.close()


# In[21]:


import os
print(os.getcwd())


# In[28]:


import pandas as pd
df = pd.read_csv('netflix_titles.csv')


# In[41]:


import sqlalchemy as sal
engine = sal.create_engine('mssql://Faisal/master?driver=ODBC+Driver+17+for+SQL+Server')
conn = engine.connect()


# In[42]:


df.to_sql('netflix_raw', con = conn, index = False, if_exists = 'append')
conn.close()


# In[33]:


len(df)


# In[35]:


df[df.show_id == 's5023']


# In[40]:


max(df.cast.dropna().str.len())


# In[ ]:




