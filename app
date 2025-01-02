import streamlit as st
import gspread
from google.oauth2.service_account import Credentials
from gspread_dataframe import get_as_dataframe
import pandas as pd

# Authenticate and connect to Google Sheets using Streamlit Secrets
def authenticate_gspread():
    credentials = Credentials.from_service_account_info(
        st.secrets["gspread_credentials"],  # Use the service account credentials stored in Streamlit Secrets
        scopes=["https://www.googleapis.com/auth/spreadsheets"]
    )
    gc = gspread.authorize(credentials)
    return gc

# Load data from a specific worksheet
def load_sheet_data(sheet_name, worksheet_name):
    gc = authenticate_gspread()
    workbook = gc.open(sheet_name)
    worksheet = workbook.worksheet(worksheet_name)
    df = get_as_dataframe(worksheet, evaluate_formulas=True)
    df = df.dropna(how="all", axis=0).dropna(how="all", axis=1)  # Clean up empty rows and columns
    return df

# Streamlit app
def main():
    st.title("Interactive Google Sheets Viewer")

    # Name of your Google Spreadsheet
    spreadsheet_name = "Copia di RANKINGS"  # Replace with your spreadsheet's name

    # Sidebar for navigation
    st.sidebar.title("Navigation")
    selected_table = st.sidebar.radio("Choose a table to view:", ["Classifica", "Partite"])

    # Load and display data
    try:
        df = load_sheet_data(spreadsheet_name, selected_table)
        st.header(f"{selected_table} Table")
        st.dataframe(df)

        # Sorting
        st.subheader("Sort the Table")
        sort_column = st.selectbox("Sort by column:", df.columns)
        ascending = st.radio("Sort order:", ["Ascending", "Descending"]) == "Ascending"
        sorted_df = df.sort_values(by=sort_column, ascending=ascending)
        st.dataframe(sorted_df)

        # Filtering
        st.subheader("Filter the Table")
        filter_column = st.selectbox("Filter by column:", df.columns)
        filter_value = st.text_input(f"Enter value to filter {filter_column}:")
        if filter_value:
            filtered_df = df[df[filter_column].astype(str).str.contains(filter_value, case=False)]
            st.dataframe(filtered_df)

    except Exception as e:
        st.error(f"Error loading {selected_table} table: {e}")

if __name__ == "__main__":
    main()
