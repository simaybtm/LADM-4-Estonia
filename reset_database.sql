-- reset_database.sql

DO $$ 
DECLARE
    tbl RECORD;
    seq RECORD;
BEGIN
    -- Truncate the tables
    FOR tbl IN 
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
        AND table_name NOT IN (
            'est_greennetworktype',
            'est_transportinfrastructuretype',
            'la_mediatype',
            'la_multimediatype',
            'la_spatialsourcetype',
            'la_surfacerelationtype',
            'la_surveypurposetype',
            'sp_higherlevelspacefunction',
            'sp_permittype',
            'sp_spacefunctiontype',
            'sp_statustype',
            'sp_subspacefunctiontype',
            'ci_rolecode',  
            'spatial_ref_sys'
        )
    LOOP
        EXECUTE 'TRUNCATE TABLE ' || quote_ident(tbl.table_name) || ' CASCADE';
    END LOOP;

    -- Reset the sequences
    FOR seq IN
        SELECT sequence_name
        FROM information_schema.sequences
        WHERE sequence_schema = 'public'
        AND sequence_name NOT IN (
            'est_greennetworktype_id_seq',
            'est_transportinfrastructuretype_id_seq',
            'la_mediatype_id_seq',
            'la_multimediatype_id_seq',
            'la_spatialsourcetype_id_seq',
            'la_surfacerelationtype_id_seq',
            'la_surveypurposetype_id_seq',
            'sp_higherlevelspacefunction_id_seq',
            'sp_permittype_id_seq',
            'sp_spacefunctiontype_id_seq',
            'sp_statustype_id_seq',
            'sp_subspacefunctiontype_id_seq',
            'ci_rolecode_id_seq', 
            'spatial_ref_sys_srid_seq'

        )
    LOOP
        EXECUTE 'SELECT setval(''' || quote_ident(seq.sequence_name) || ''', 1, false)';
    END LOOP;
END $$;
