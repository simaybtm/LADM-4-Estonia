### model_creation.py
import _1_create_synthetic_data
import _2_synthetic_model

def main():
    # Create synthetic data
    synthetic_data = _1_create_synthetic_data.main()
    
    # Train the model
    output_csv = _2_synthetic_model.main()
    
    return output_csv
    
if __name__ == '__main__':
    main()
    