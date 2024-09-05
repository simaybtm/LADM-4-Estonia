### main.py

import os
import subprocess
import pandas as pd
import platform
import glob
from sqlalchemy import create_engine, text, inspect
from sqlalchemy_utils import database_exists, create_database, drop_database
from sqlalchemy import MetaData
import model_creation # ML algorithm
import getpass  # secure password input

def initialize_environment():
    # Initialize the environment by installing required libraries
    subprocess.run(['pip3', 'install', 'pandas', 'scikit-learn', 'joblib', 'sqlalchemy', 'psycopg2-binary', 'sqlalchemy-utils'], capture_output=True)
    print("\n --Environment initialized.")
    print(" --Required libraries installed.")
    print("\n--------------------------------------------------------------------------------------------------------\n")


def run_machine_learning_algorithm(output_csv_path):
    '''
    - Run the machine learning algorithm to predict the Estonian discipline name 'model_creation.py'.
    - Output the result to a CSV file 'output.csv'.
    '''
    print("MACHINE LEARNING ALGORITHM SETUP")
    print("\n --Running machine learning algorithm to predict Estonian discipline name...\n")
    model_creation.main()

    try:
        # Read the CSV into a DataFrame
        predictions_df = pd.read_csv(output_csv_path)
                
        # Save the DataFrame to a new CSV file if needed
        predictions_df.to_csv('output.csv', index=False)
        
        print(f"\n --Machine learning prediction completed. Results saved to '{output_csv_path}'.")
    except FileNotFoundError:
        print(f"Error: File '{output_csv_path}' not found.")
    except Exception as e:
        print(f"Error: {e}")

    # Check for existence of output.csv before running ML algorithm
    if not os.path.exists(output_csv_path):
        print(f"ERROR: '{output_csv_path}' does not exist. Make sure FME or other processes generate it.")
        exit(1)

def check_and_create_ladm_database(db_user, db_password, db_host, db_port, db_name, sql_dump_path='database_v15.sql'):
    '''
    - Check if the LADM database exists, and create it if it does not.
    - Ask the user if the LADM database is up to date.
    - If not up to date, delete and recreate the database and schema.
    - Load the schema from the SQL dump file using psql.
    '''

    db_url = f'postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}'
    db_engine = create_engine(db_url)

    if database_exists(db_engine.url):
        print(" --Dropping existing LADM database...")
        drop_database(db_engine.url)

    print(" --Creating LADM database...")
    create_database(db_engine.url)

    # Connect to the new database
    with db_engine.connect() as connection:
        # Check if the 'public' schema exists and drop it if it does
        schema_exists = connection.execute(text("SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'public'")).fetchone()
        if schema_exists:
            connection.execute(text("DROP SCHEMA public CASCADE"))

        # Create the 'public' schema
        connection.execute(text("CREATE SCHEMA public"))

    # Use psql to load the schema from the SQL dump file
    try:
        command = [
            'psql',
            '-U', db_user,
            '-d', db_name,
            '-h', db_host,
            '-p', db_port,
            '-f', sql_dump_path
        ]

        # Set the PGPASSWORD environment variable to avoid password prompt
        env = os.environ.copy()
        env['PGPASSWORD'] = db_password

        print(f" --Loading SQL dump file '{sql_dump_path}' into database...")
        result = subprocess.run(command, env=env, capture_output=True, text=True)

        # Check if the command executed successfully
        if result.returncode == 0:
            print(f" --SQL dump file '{sql_dump_path}' loaded successfully.")
        else:
            print(f" --Error loading SQL dump file '{sql_dump_path}':")
            print(result.stderr)

    except Exception as e:
        print(f" --Error loading SQL dump file '{sql_dump_path}': {e}")

    # Check if tables were created after loading the dump file
    with db_engine.connect() as connection:
        schema_created = connection.execute(text("SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'public'")).fetchone()
        if schema_created:
            print(" --LADM schema created.")
            # Check if tables were created (e.g. est_detailed_plan)
            est_detailed_plan_exists = connection.execute(text("SELECT table_name FROM information_schema.tables WHERE table_name = 'est_detailed_plan'")).fetchone()
            if est_detailed_plan_exists:
                print(" --LADM tables created.\n")
            else:
                print(" --ERROR: LADM tables not created.\n")
        else:
            print(" --ERROR: LADM schema not created.\n")

def find_fme_executable():
    current_platform = platform.system()

    if current_platform == 'Windows':
        possible_paths = [
            r'C:\Program Files\FME*\fme.exe',
            r'C:\Program Files\FME*\fme*.exe'
        ]
    elif current_platform == 'Darwin':  # macOS
        possible_paths = [
            '/Applications/FME*.app/Contents/MacOS/fme',
            '/usr/local/fme*/fme',
            '/Library/FME/2024.0/bin/fme'
        ]
    else:
        print("ERROR: Could not find FME executable path.")
        return None  
    
    for path_pattern in possible_paths:
        matches = glob.glob(path_pattern)
        if matches:
            return matches[0]  # Return the first match found
        
    print("ERROR: FME executable not found.")
    return None  # Return None if no executable found

def run_fme_workbench(input_ifc_directory, fme_script_path, output_csv_path):
    print("\n--------------------------------------------------------------------------------------------------------\n")
    print("FME WORKBENCH SETUP")
    # Find the FME workbench file in the project repository
    workbench_path = os.path.join(os.path.dirname(__file__), fme_script_path)
    print(f"\n --Running FME workbench: {workbench_path}")
    print(f" --Input IFC directory: {input_ifc_directory}")
    print("\n")

    # Find the FME executable
    fme_executable = find_fme_executable()
    if not fme_executable:
        print("ERROR: FME executable not found.")
        return

    # Construct the command to run the FME workbench
    command = [
        fme_executable,   # FME command line executable
        workbench_path,   # Path to FME workbench file (.fmw)
        "--SourceDataset", input_ifc_directory,  # Pass dataset path as argument
        "--SourceDataset", output_csv_path  # Pass output CSV path as argument
    ]

    # Run the command
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    # Print the output and errors
    print(result.stdout)
    print(result.stderr)

    print(f"\n --FME workbench '{workbench_path}' completed!\n")

def table_exists(engine, table_name, schema=None):
    inspector = inspect(engine)
    return table_name in inspector.get_table_names(schema=schema)

def main():
    print("\n--------------------------------------------------------------------------------------------------------\n")
    print("This script will: ")
    print(" 1. Run a machine learning algorithm to predict the Estonian discipline name.")
    print(" 2. Create an LADM database if it does not exist.")
    print(" 3. Run an FME script to process multiple input IFC files and write the data to the LADM database.")
    print("\n--------------------------------------------------------------------------------------------------------\n")


    input_ifc_directory = input("> Enter the path to the directory/folder containing the IFC files: ")
    while not glob.glob(os.path.join(input_ifc_directory, '*.ifc')) and not glob.glob(os.path.join(input_ifc_directory, '*.ifcxml')):
        print(" ERROR: No IFC files found in the provided directory.")
        print(" Found files:", glob.glob(os.path.join(input_ifc_directory, '*')))
        input_ifc_directory = input("\n> Re-enter the path to the directory/folder containing the IFC files: ")
    print("\n--------------------------------------------------------------------------------------------------------\n")

    print("DATABASE SETUP")
    print("\n### The following steps will create an LADM database if it does not exist OR update the existing database (delete and recreate) ###")
    is_up_to_date = input("\n > Is your LADM database up to date? (yes/no): ").strip().lower()
    if is_up_to_date not in ['yes', 'no']:
        print(" ERROR: Invalid input. Please enter 'yes' or 'no'.")
        return
    
    print("\n ### Please provide the database credentials ###")
    db_user = input("  1. Enter the database user (default: postgres): ") or 'postgres'
    db_password = getpass.getpass("  2. Enter the database password (not visible for security): ")
    db_host = input("  3. Enter the database host (default: localhost): ") or 'localhost'
    db_port = input("  4. Enter the database port (default: 5432): ") or '5432'
    db_name = 'LADM_Thesis'

    print("\n")

    # To later print the number of records uploaded to the tables
    db_url = f'postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}'
    db_engine = create_engine(db_url)

    if is_up_to_date == 'no':
        check_and_create_ladm_database(db_user, db_password, db_host, db_port, db_name)
        b_est_detailed_plan_count = 0
        b_est_detail_unit_count = 0
    else:
        with db_engine.connect() as connection:
            if table_exists(db_engine, 'est_detailed_plan'):
                b_est_detailed_plan_count = connection.execute(text("SELECT COUNT(*) FROM est_detailed_plan")).fetchone()[0]
            else:
                b_est_detailed_plan_count = 0

            if table_exists(db_engine, 'est_detail_unit'):
                b_est_detail_unit_count = connection.execute(text("SELECT COUNT(*) FROM est_detail_unit")).fetchone()[0]
            else:
                b_est_detail_unit_count = 0
    
    print("\n--------------------------------------------------------------------------------------------------------\n")

    output_csv_path = 'output.csv'
    fme_script_path = 'extract_data.fmw'

    initialize_environment()
    run_machine_learning_algorithm(output_csv_path)
    run_fme_workbench(input_ifc_directory, fme_script_path, output_csv_path)

    print("\n--------------------------------------------------------------------------------------------------------\n")
    print("OVERVIEW OF DATA UPLOADED TO DATABSE\n")

    # Print the number of records uploaded to the tables
    with db_engine.connect() as connection:
        if table_exists(db_engine, 'est_detailed_plan'):
            a_est_detailed_plan_count = connection.execute(text("SELECT COUNT(*) FROM est_detailed_plan")).fetchone()[0]
        else:
            a_est_detailed_plan_count = 0

        if table_exists(db_engine, 'est_detail_unit'):
            a_est_detail_unit_count = connection.execute(text("SELECT COUNT(*) FROM est_detail_unit")).fetchone()[0]
        else:
            a_est_detail_unit_count = 0

    if is_up_to_date == 'no':
        print(f" Number of records uploaded to 'est_detailed_plan' table: {a_est_detailed_plan_count}")
        print(f" Number of records uploaded to 'est_detail_unit' table: {a_est_detail_unit_count}")
    else:
        print(f"\n Number of new records uploaded to 'est_detailed_plan' table: {a_est_detailed_plan_count - b_est_detailed_plan_count}")
        print(f" Number of new records uploaded to 'est_detail_unit' table: {a_est_detail_unit_count - b_est_detail_unit_count}")

    print("\n********************************************************************************************************\n")
    print ("### If FME workbench completed successfully, the data should be loaded into the LADM database ###")
    print ("### If 'Translation FAILED', please check the FME log file (extract_data.log) created for errors ###")
    print("\n********************************************************************************************************\n")
    
if __name__ == "__main__":
    main()