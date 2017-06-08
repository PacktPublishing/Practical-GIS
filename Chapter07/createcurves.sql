CREATE OR REPLACE FUNCTION CreateCurve(geom geometry, percent int DEFAULT 40)
    RETURNS geometry AS
$$
DECLARE
    result text;
    p0 geometry;
    p1 geometry;
    p2 geometry;
    intp geometry;
    tempp geometry;
    geomtype text := ST_GeometryType(geom);
    factor double precision := percent::double precision / 200;
    i integer;
BEGIN
    IF percent < 0 OR percent > 100 THEN
        RAISE EXCEPTION 'Smoothing factor must be between 0 and 100';
    END IF;
    IF geomtype != 'ST_LineString' OR factor = 0 THEN
        RETURN geom;
    END IF;
    result := 'COMPOUNDCURVE((';
    p0 := ST_PointN(geom, 1);
    IF ST_NPoints(geom) = 2 THEN
        p1:= ST_PointN(geom, 2);
        result := result || ST_X(p0) || ' ' || ST_Y(p0) || ',' || ST_X(p1) || ' ' || ST_Y(p1) || '))';
    ELSE
        FOR i IN 2..(ST_NPoints(geom) - 1) LOOP
            p1 := ST_PointN(geom, i);
            p2 := ST_PointN(geom, i + 1);
            result := result || ST_X(p0) || ' ' || ST_Y(p0) || ',';
            tempp := ST_Line_Interpolate_Point(ST_MakeLine(p1, p0), factor);
            p0 := ST_Line_Interpolate_Point(ST_MakeLine(p1, p2), factor);
            intp := ST_Line_Interpolate_Point(
                ST_MakeLine(
                    ST_Line_Interpolate_Point(ST_MakeLine(p0, p1), 0.5),
                    ST_Line_Interpolate_Point(ST_MakeLine(tempp, p1), 0.5)
                ), 0.5);
            result := result || ST_X(tempp) || ' ' || ST_Y(tempp) || '),CIRCULARSTRING(' || ST_X(tempp) || ' ' || ST_Y(tempp) || ',' || ST_X(intp) || ' ' ||
            ST_Y(intp) || ',' || ST_X(p0) || ' ' || ST_Y(p0) || '),(';
        END LOOP;
        result := result || ST_X(p0) || ' ' || ST_Y(p0) || ',' || ST_X(p2) || ' ' || ST_Y(p2) || '))';
    END IF;
    RETURN ST_SetSRID(result::geometry, ST_SRID(geom));
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;