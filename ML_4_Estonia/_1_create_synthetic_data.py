### _1_create_synthetic_data.py
import pandas as pd

"""
This script creates synthetic data for the layer mapping model.
"""

def main():
    # Define the extended synthetic data
    synthetic_data = {
        'discipline': [
            'dp_hoone', 'dp_hoone', 'dp_hoone', 'dp_hoone', 'dp_hoone', 'dp_hoone', 'dp_hoone', 'dp_hoone', 'dp_hoone', 'dp_hoone',
            'dp_hoonestus', 'dp_hoonestus', 'dp_hoonestus', 'dp_hoonestus', 'dp_hoonestus', 'dp_hoonestus', 'dp_hoonestus', 'dp_hoonestus', 'dp_hoonestus', 'dp_hoonestus',
            'dp_transp', 'dp_transp', 'dp_transp', 'dp_transp', 'dp_transp', 'dp_transp', 'dp_transp', 'dp_transp', 'dp_transp', 'dp_transp',
            'dp_haljastus', 'dp_haljastus', 'dp_haljastus', 'dp_haljastus', 'dp_haljastus', 'dp_haljastus', 'dp_haljastus', 'dp_haljastus', 'dp_haljastus', 'dp_haljastus',
            'dp_krunt', 'dp_krunt', 'dp_krunt', 'dp_krunt', 'dp_krunt', 'dp_krunt', 'dp_krunt', 'dp_krunt', 'dp_krunt', 'dp_krunt',
            'dp_krundiSihtotstarve', 'dp_krundiSihtotstarve', 'dp_krundiSihtotstarve', 'dp_krundiSihtotstarve', 'dp_krundiSihtotstarve', 'dp_krundiSihtotstarve', 'dp_krundiSihtotstarve', 'dp_krundiSihtotstarve', 'dp_krundiSihtotstarve', 'dp_krundiSihtotstarve',
            'dp_servituut', 'dp_servituut', 'dp_servituut', 'dp_servituut', 'dp_servituut', 'dp_servituut', 'dp_servituut', 'dp_servituut', 'dp_servituut', 'dp_servituut',
            'dp_sund', 'dp_sund', 'dp_sund', 'dp_sund', 'dp_sund', 'dp_sund', 'dp_sund', 'dp_sund', 'dp_sund', 'dp_sund',
            'dp_tehno', 'dp_tehno', 'dp_tehno', 'dp_tehno', 'dp_tehno', 'dp_tehno', 'dp_tehno', 'dp_tehno', 'dp_tehno', 'dp_tehno',
            'dp_tingimus', 'dp_tingimus', 'dp_tingimus', 'dp_tingimus', 'dp_tingimus', 'dp_tingimus', 'dp_tingimus', 'dp_tingimus', 'dp_tingimus', 'dp_tingimus',
            'dp_vaartloodus', 'dp_vaartloodus', 'dp_vaartloodus', 'dp_vaartloodus', 'dp_vaartloodus', 'dp_vaartloodus', 'dp_vaartloodus', 'dp_vaartloodus', 'dp_vaartloodus', 'dp_vaartloodus',
            'dp_vaartMiljoo', 'dp_vaartMiljoo', 'dp_vaartMiljoo', 'dp_vaartMiljoo', 'dp_vaartMiljoo', 'dp_vaartMiljoo', 'dp_vaartMiljoo', 'dp_vaartMiljoo', 'dp_vaartMiljoo', 'dp_vaartMiljoo',
            'dp_vaartPollum', 'dp_vaartPollum', 'dp_vaartPollum', 'dp_vaartPollum', 'dp_vaartPollum', 'dp_vaartPollum', 'dp_vaartPollum', 'dp_vaartPollum', 'dp_vaartPollum', 'dp_vaartPollum', 'dp_plan_ala'
        ],
        'element_type': [
            'NaN', 'elamumaa', 'ärimaa', 'kaubandus', 'haridus', 'tööstus', 'põllumajandus', 'metsandus', 'lähiajalooline', 'tehnotaristu',
            'maapealne', 'maa_alune', 'sissepääs', 'terrass', 'katus', 'vundament', 'varikatus', 'sokkel', 'piirdeaed', 'sillutis',
            'NaN', 'teed', 'sild', 'raudtee', 'jalgrattatee', 'tänav', 'ristmik', 'parkla', 'peatänav', 'kaarsild',
            'NaN', 'pargid', 'rohealad', 'spordivaljak', 'lasteplats', 'mänguväljak', 'koertepark', 'haljastus', 'rannaala', 'metssalu',
            'NaN', 'elamumaa', 'ärimaa', 'maatulundusmaa', 'metsamaa', 'põllumaa', 'rekreatsioonimaa', 'sotsiaalmaa', 'elamuehituseks', 'arendusalad',
            'elamumaa', 'ärimaa', 'rekreatsioonimaa', 'muud', 'elamumaa', 'ärimaa', 'rekreatsioonimaa', 'muud', 'elamumaa', 'ärimaa',
            'NaN', 'krundi_tänav', 'krundi_tänav', 'NaN', 'krundi_tänav', 'NaN', 'krundi_tänav', 'NaN', 'krundi_tänav', 'NaN',
            'NaN', 'eraldis', 'eraldis', 'NaN', 'eraldis', 'NaN', 'eraldis', 'NaN', 'eraldis', 'NaN',
            'NaN', 'side', 'elektri', 'gaas', 'veevärk', 'kanalisatsioon', 'jahutus', 'soojus', 'ventilatsioon', 'valgus',
            'NaN', 'ehituskeeluala', 'metsa', 'parkmets', 'haljastus', 'looduskaitse', 'mälestised', 'muinsuskaitse', 'miljöö', 'piirkond',
            'NaN', 'kaitseala', 'rahvuspark', 'looduskaitseala', 'maastikukaitseala', 'hoiuala', 'looduspark', 'maastik', 'läänemaa', 'lahemaa',
            'NaN', 'kultuuriväärtus', 'miljööväärtus', 'ajaloomälestis', 'muinsuskaitseala', 'rahvusväärtus', 'kaitsealune', 'pärand', 'kultuurikaitse', 'kultuurimälestis',
            'NaN', 'põllumajandusmaa', 'karjamaa', 'heinamaa', 'räätsamaa', 'põllumaaväärtus', 'viljakus', 'rannakarjamaad', 'soomaa', 'looduslik','NaN'
        ]
    }

    # Print number of records
    #print(f"Number of records: {len(synthetic_data['discipline'])}")

    # Additional discipline and element_type to be added
    additional_discipline = [
        'dp_haljastus_katuse', 'dp_haljastus_muru', 'dp_haljastus_puittaim', 'dp_hoone', 'dp_transp_klt', 'dp_transp_klt_olemas', 'dp_transp_klt_ratas'
    ]
    additional_element_type = [
        'NaN', 'NaN', 'NaN', 'NaN', 'NaN', 'NaN', 'NaN'
    ]

    # Extend the existing lists with the additional elements
    synthetic_data['discipline'].extend(additional_discipline)
    synthetic_data['element_type'].extend(additional_element_type)

    # Print number of records
    #print(f"Number of records after first additionals: {len(synthetic_data['discipline'])}")

    # Additional discipline and element_type to be added based on semantics
    additional_discipline_semantics = [
        'hoone', 'hoone', 'hoone', 'hoone', 'hoone', 'hoone', 'hoone', 'hoone', 'hoone', 'hoone',
        'hoonestus', 'hoonestus', 'hoonestus', 'hoonestus', 'hoonestus', 'hoonestus', 'hoonestus', 'hoonestus', 'hoonestus', 'hoonestus',
        'transp', 'transp', 'transp', 'transp', 'transp', 'transp', 'transp', 'transp', 'transp', 'transp',
        'haljastus', 'haljastus', 'haljastus', 'haljastus', 'haljastus', 'haljastus', 'haljastus', 'haljastus', 'haljastus', 'haljastus',
        'krunt', 'krunt', 'krunt', 'krunt', 'krunt', 'krunt', 'krunt', 'krunt', 'krunt', 'krunt',
        'krundiSihtotstarve', 'krundiSihtotstarve', 'krundiSihtotstarve', 'krundiSihtotstarve', 'krundiSihtotstarve', 'krundiSihtotstarve', 'krundiSihtotstarve', 'krundiSihtotstarve', 'krundiSihtotstarve', 'krundiSihtotstarve',
        'servituut', 'servituut', 'servituut', 'servituut', 'servituut', 'servituut', 'servituut', 'servituut', 'servituut', 'servituut',
        'sund', 'sund', 'sund', 'sund', 'sund', 'sund', 'sund', 'sund', 'sund', 'sund',
        'tehno', 'tehno', 'tehno', 'tehno', 'tehno', 'tehno', 'tehno', 'tehno', 'tehno', 'tehno',
        'tingimus', 'tingimus', 'tingimus', 'tingimus', 'tingimus', 'tingimus', 'tingimus', 'tingimus', 'tingimus', 'tingimus',
        'vaartloodus', 'vaartloodus', 'vaartloodus', 'vaartloodus', 'vaartloodus', 'vaartloodus', 'vaartloodus', 'vaartloodus', 'vaartloodus', 'vaartloodus',
        'vaartMiljoo', 'vaartMiljoo', 'vaartMiljoo', 'vaartMiljoo', 'vaartMiljoo', 'vaartMiljoo', 'vaartMiljoo', 'vaartMiljoo', 'vaartMiljoo', 'vaartMiljoo',
        'vaartPollum', 'vaartPollum', 'vaartPollum', 'vaartPollum', 'vaartPollum', 'vaartPollum', 'vaartPollum', 'vaartPollum', 'vaartPollum', 'vaartPollum'
    ]
    # Create a list of NaN values to match the length of additional_discipline_semantics
    additional_element_type_semantics = ['NaN'] * len(additional_discipline_semantics)

    # Extend the existing lists with the additional elements based on semantics
    synthetic_data['discipline'].extend(additional_discipline_semantics)
    synthetic_data['element_type'].extend(additional_element_type_semantics)

    # Print the updated number of records
    #print(f"Number of records after second additionals: {len(synthetic_data['discipline'])}")

    # Additional examples for dp_plan_ala
    additional_plan_ala = [
        'dp_plan_ala', 'dp_plan_ala', 'dp_plan_ala', 'dp_plan_ala', 'dp_plan_ala',
        'dp_plan_ala', 'dp_plan_ala', 'dp_plan_ala', 'dp_plan_ala', 'dp_plan_ala',
        'dp_plan_ala', 'dp_plan_ala', 'dp_plan_ala', 'dp_plan_ala', 'dp_plan_ala',
        'dp_plan_ala', 'dp_plan_ala', 'dp_plan_ala', 'dp_plan_ala', 'dp_plan_ala'
    ]

    # Extend the existing lists with additional examples for dp_plan_ala
    synthetic_data['discipline'].extend(additional_plan_ala)
    synthetic_data['element_type'].extend(['NaN'] * len(additional_plan_ala))

    # Print the updated number of records
    #print(f"Number of records after adding more dp_plan_ala examples: {len(synthetic_data['discipline'])}")

    # Convert to a DataFrame
    synthetic_df = pd.DataFrame(synthetic_data)

    # Save to CSV
    synthetic_df.to_csv('extended_synthetic_layer_mapping.csv', index=False)

    print(" ---Extended synthetic data CSV created ('extended_synthetic_layer_mapping.csv').")

    return synthetic_df

if __name__ == '__main__':
    main()
