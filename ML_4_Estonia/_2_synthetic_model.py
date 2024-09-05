### _2_synthetic_model.py
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import SVC
from sklearn.pipeline import make_pipeline
import joblib

"""
This script creates a machine learning model from the synthetic data.
INPUT: extended_synthetic_layer_mapping.csv
OUTPUT: synthetic_model.pkl, output.csv
"""

def main():
    # Load the extended synthetic data
    synthetic_data = pd.read_csv('extended_synthetic_layer_mapping.csv')

    # Combine 'discipline' and 'element_type' into a single feature
    synthetic_data['combined'] = synthetic_data['discipline'] + ' ' + synthetic_data['element_type'].fillna('')

    # Extract the combined data
    X_synthetic = synthetic_data['combined']
    y_synthetic = synthetic_data['discipline']

    # Create a pipeline that vectorizes the text and then applies a Support Vector Classifier
    model = make_pipeline(TfidfVectorizer(), SVC(kernel='linear'))

    # Train the model
    model.fit(X_synthetic, y_synthetic)

    # Save the trained model to a file
    joblib.dump(model, 'synthetic_model.pkl')

    print(" ---Synthetic ML model was created using the CSV.")
    
    # Predict all the categories
    predictions = model.predict(X_synthetic)
    
    # Add predictions to the synthetic data
    synthetic_data['predicted_discipline'] = predictions
    
    # Delete duplicates
    synthetic_data.drop_duplicates(subset='discipline', keep='first', inplace=True)
    
    # Save the synthetic data with predictions to a CSV file
    synthetic_data.to_csv('output.csv', index=False)
    if len(synthetic_data) > 0:
        print(" ---Current predicted discipline names:", len(synthetic_data), "rows")
        print(" ---Predictions of the model saved to 'output.csv' to be used as input in FME.")
    else:
        print(" ---No predictions were made.")

    # Return the output CSV path
    return 'output.csv'

if __name__ == '__main__':
    main()