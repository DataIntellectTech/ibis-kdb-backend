# ibis-kdb-backend

## Installation
### Python version
Requires Python <3.11 for installation of requirements. As of 23/02/2023 the package Pyarrow doesn't work in python >=3.11 and so can't build the dependencies correctly. To combat this use an earlier version of Python. 

I recommend installing a virtual environment like below. Python executable path may be similar to `"C:\User\USERNAME\AppData\Local\Programs\Python\Python310\python.exe"`.

```bash
virtualenv --python="path\to\python310executable" "ibis-venv-py" --prompt="ibis-venv-py310"

# to activate
ibis-venv-py\Scripts\activate 

# to deactivate
deactivate                    
```
### Ibis Preresequites
[Ibis](https://ibis-project.org/) is a python library so you must have python installed on your device to use it. Installation instructions can be found [here](https://www.python.org/downloads/).

If installing on windows make sure to have Microsoft Visual C++ 14.0 or greater installed with Microsoft C++ build tools [here](https://visualstudio.microsoft.com/visual-cpp-build-tools/)

To get started with Ibis you need to install the Ibis framework with:
```bash
pip install ibis-framework
```

Next, clone this repo into an easily accessable directory. Then cd into your clone and run the following commands:
```bash
pip install -r requirements.txt
pip install -e .
```

For Ibis to work properly with kdb you will need to ensure you are running the correct version of pandas and numpy. To check this run:
```bash
pip list
```
Pandas should be version 1.3.5 and numpy should be version 1.23.4

If you need to install a different version of them run the following commands. This may take some time.
```bash
python -m pip install pandas==1.3.5
python -m pip install numpy==1.23.4 
```

Finally in order to use the kdb backend you will need to edit the entry_points.txt file. This will be located wherever your python dependancies are; for me the file path was:
```bash
/Library/Frameworks/Python.framework/Versions/3.11/lib/python3.11/site-packages/ibis_framework-3.2.0.dist-info/entry_points.txt
```

You will need to add the following line to the end of the file:
```bash
kdb=ibis.backends.kdb
```

## Getting started 
First you need to have a KDB+ session open to connect to by port either on own system or on Homer. Then to use ibis you must start a python session. Once in the session you will need to import ibis:
```python
>>> import ibis
```

Next open a connection to your kdb session. By default this will be looking for a process running on your localhost at port 8000.
```python
>>> q=ibis.kdb.connect()
```

This should print the following confirming it is connected:
```python
:localhost:8000
IPC version: 3. Is connected: True
```
Now that your connection is established you can pass queries into it.

If you want to connect to a process on homer use the following instead:
```python
>>> q=ibis.kdb.connect(host="81.150.99.19",port=8000)
```
## Function descriptions
We created a class BaseKDBBackend that inherited everything from the BaseBackend as all backends must subclass it. The main functions that we care about for this use case are connect(), table(), compile(), and execute(). Ibis works by allowing the user to connect to the database by its connect() function. The user can then specify a table from the database with the table() function and it builds an Ibis expression to hold the information about the table in question. Below are descriptions of the four main functions.

`connect()`
 This function uses the function do_connect() which uses qPython to connect to a q process and returns the result in a pandas dataframe. By default, it connects to the localhost with port number 8000, but these can be specified when calling the function. 

`table()`
 This function is the main part of this example. It takes in the name of the table you are wanting to interact with as a string, creates an Ibis schema of the table by querying the KDB+ process for the table's meta information and then translates it. It then creates an Ibis table expression with that schema which can be then interacted with.  

The idea of this is that the Ibis table is basically a container that knows the schema of the table server side, and any manipulations that you do to it is saved and these manipulations can then be compiled and translated to a QSQL query string that can then be executed server side. 

`compile()` 
 Uses the KDBCompiler that uses Clickhouse translators and select builders to compile the manipulations on the table expression into a QSQL query string. Clickhouse was used as a base as it was also a string generating backend and used the same table expression as the KDB+ one. This function returns the string containing the QSQL query. 

`execute()`
 This function calls the compile() function and sends it to the KDB+ process as a sync message. It returns the result in a pandas dataframe.
 
## Example query
Right now the only function that has been programmed to work with kdb to apply aggregations is the table() function. We use the market data quant.q script for generating test tables to work with from [this link](https://github.com/AquaQAnalytics/Training-docs/blob/b0198e60f48a5fe8ecb1d9c856e20a8bd6cd0eaa/docs/kdb/resources/quantq.q). Also this assumes that options.interactive=False, it set for true is not yet implemented. All this means is that the functions don't execute immediately upon calling and have to be called with the execute function as shown below.

The table function takes in the table name as a string, queries the schema using the meta keyword from the q process, translates this into an ibis schema and creates an ibis table expression using this schema. 

This function takes the following arguments: `table(self, table: str)`

An Example query with aggregation would be:
```python
>>> trade=q.table(table="trade")
>>> a=trade.group_by("sym").aggregate(trade["price"].mean().name("averageprice"))
>>> q.execute(a)
```
You should get something that looks like this:

|sym     |price |
|--------|------|
|APPL    |109.34|
|CAT     |252.32|
|GOOG    |209.11|
|NYSE    |57.59 |

Other functions/features that have working capabilities are below. 
```python
>>> trade.schema()  # to inspect the schema of the table
>>> q.compile(a)    # to inspect the qsql query generated by the aggregations
>>> q.list_tables() # queries the q process for the list of tables available
>>> q.head("trade") # queries the top 5 rows from the table
>>> q.create_table("table_name",schema=sch) # creates table on kdb process with schema given, and creates ibis version. 
>>> q.drop_table("table_name")              # drops table from kdb process if it exists
```
