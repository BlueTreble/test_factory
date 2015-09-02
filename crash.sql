BEGIN;
\i test/helpers/tap_setup.sql

CREATE EXTENSION test_factory VERSION '0.1.1';
SET search_path=tap;
\i test/helpers/create.sql

SELECT tf.register(
  'customer'
  , array[
    row(
      'insert'
      , $$INSERT INTO customer VALUES (DEFAULT, 'first', 'last' ) RETURNING *$$
    )::tf.test_set
    , row(
      'function'
      , $$SELECT * FROM customer__add( 'func first', 'func last' )$$
    )::tf.test_set
  ]
);
SELECT tf.register(
  'invoice'
  , array[
      row(
        'base'
        , $$INSERT INTO invoice VALUES(
            DEFAULT
            , (tf.get( NULL::customer, 'insert' )).customer_id
            , current_date
            , current_date + 30
          ) RETURNING *$$
      )::tf.test_set
  ]
);

SELECT no_plan();
--SELECT * FROM tf.get( NULL::invoice, 'base' );
SELECT results_eq(
  --$$SELECT * FROM tf.get( NULL::customer, 'insert' )$$
  $$SELECT * FROM tf.get( NULL::invoice, 'base' )$$
  , $$VALUES( 1, 1, current_date, current_date + 30 )$$
  , 'invoice factory output'
);
/*
*/

