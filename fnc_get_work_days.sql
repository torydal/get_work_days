/* ������ �������� ��������� � ���������� ��������� ������� �� 2020�., ���
 holiday=1 - ����������� ����, workday=1 - ������� ��������. */

drop table calendar_tab cascade constraints;

create table calendar_tab
(
    day       date,
    holiday   number,
    workday   number
);


create unique index pk_calendar_tab_day
    on calendar_tab (day);

alter table calendar_tab
    add (
        constraint pk_calendar_tab_day primary key (day)
            using index pk_calendar_tab_day enable validate);

/*���������*/

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('01/01/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('02/01/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('03/01/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('06/01/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('07/01/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('08/01/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('24/02/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('09/03/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('01/05/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('04/05/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('05/05/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('11/05/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('12/06/2020', 'DD/MM/YYYY'), 1, 0);

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('04/11/2020', 'DD/MM/YYYY'), 1, 0);

/*���. ��������*/

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('27/01/2020', 'DD/MM/YYYY'), 1, 0);

/*������� ��������*/

insert into  calendar_tab (day, holiday, workday)
     values  (to_date ('26/01/2020', 'DD/MM/YYYY'), 0, 1);

commit;


create or replace function get_work_days (start_dt$d  in date,
                                          end_dt$d    in date)
    return integer
as
    result$i        integer := 0;
    sub_day$i       integer := 0;
    if_null$e       exception;
    check_date$e    exception;
begin
    /*�������� �� null*/
    if (start_dt$d is null or end_dt$d is null)
    then
        raise if_null$e;
    end if;

    /*��������, ��� ���� ������ < ���� ����� �������*/
    if trunc (start_dt$d) > trunc (end_dt$d)
    then
        raise check_date$e;
    end if;


    sub_day$i := trunc (end_dt$d) - trunc (start_dt$d) + 1;

    with
        t
        as
            (    select  trunc (start_dt$d) + level - 1     as cur_date
                   from  dual
             connect by  level <= sub_day$i)
    select  count (1)
      into  result$i
      from  t
     where         1 = 1
               /*�������� �� �������� � ����������� ���*/
               and (    to_char (trunc (t.cur_date),
                                 'DY',
                                 'NLS_DATE_LANGUAGE = RUSSIAN') not in
                            ('��', '��')
                    and not exists
                            (select  1
                               from  calendar_tab ct
                              where  ct.day = t.cur_date and ct.holiday = 1))
            /*�������� �� ������� ��������*/
            or exists
                   (select  1
                      from  calendar_tab ct
                     where  ct.day = t.cur_date and ct.workday = 1);

    return result$i;
exception
    when if_null$e
    then
        raise_application_error (
            -20001,
               'Input Parameters cannot be null: '
            || 'start_dt$d = '
            || nvl (to_char (start_dt$d, 'dd.mm.yyyy'), 'null')
            || '; end_dt$d = '
            || nvl (to_char (end_dt$d, 'dd.mm.yyyy'), 'null')
            || '; '
            || sqlcode
            || ' -ERROR- '
            || sqlerrm);
    when check_date$e
    then
        raise_application_error (
            -20002,
               'Start date cannot be greater than end date: '
            || 'start_dt$d = '
            || to_char (start_dt$d, 'dd.mm.yyyy')
            || '; end_dt$d = '
            || to_char (end_dt$d, 'dd.mm.yyyy')
            || '; '
            || sqlcode
            || ' -ERROR- '
            || sqlerrm);
    when others
    then
        raise_application_error (
            -20004,
               'Something is wrong: '
            || 'start_dt$d = '
            || to_char (start_dt$d, 'dd.mm.yyyy')
            || '; end_dt$d = '
            || to_char (end_dt$d, 'dd.mm.yyyy')
            || '; sub_day$i = '
            || sub_day$i
            || '; '
            || sqlcode
            || ' -ERROR- '
            || sqlerrm);
end;


/*�����*/

declare
    a  integer;
begin
    /*����-���� �1, ��� ������������� ��������� [21.01.2020;21.01.2020],
     ��������� ���������: 1 */

    a :=
        get_work_days (to_date ('21.01.2020', 'dd.mm.yyyy'),
                       to_date ('21.01.2020', 'dd.mm.yyyy'));
    dbms_output.put_line ('Work days: ' || a);

    /*����-���� �2, ��� ������������� ��������� [������_����;21.01.2020],
     ��������� ���������: 9 */

    a :=
        get_work_days (trunc (sysdate, 'yyyy'),
                       to_date ('21.01.2020', 'dd.mm.yyyy'));
    dbms_output.put_line ('Work days: ' || a);


    /*����-���� �4, ��� ������������� ��������� [22.02.2020;24.02.2020],
    ��������� ���������: 0 */
    a :=
        get_work_days (to_date ('22.02.2020', 'dd.mm.yyyy'),
                       to_date ('24.02.2020', 'dd.mm.yyyy'));
    dbms_output.put_line ('Work days: ' || a);


    /*����-���� �5, ��� ������������� ��������� [24.01.2020;27.01.2020],
     ��������� ���������: 2*/

    a :=
        get_work_days (to_date ('24.01.2020', 'dd.mm.yyyy'),
                       to_date ('27.01.2020', 'dd.mm.yyyy'));

    dbms_output.put_line ('Work days: ' || a);

    /*����-���� �6, �������� ������� ��������, ��� ������������� ��������� [25.01.2020;26.01.2020],
     ��������� ���������: 1*/

    a :=
        get_work_days (to_date ('25.01.2020', 'dd.mm.yyyy'),
                       to_date ('26.01.2020', 'dd.mm.yyyy'));

    dbms_output.put_line ('Work days: ' || a);
    
    /*����-���� �7, ���� ������ ������� �� ������ ���� ������ ���� ����� �������
    ��� ������������� ��������� [�������_����+3;�������_����],
    ��������� ���������: ������� */

--    a := get_work_days (sysdate + 3, sysdate);
--    dbms_output.put_line ('Work days: ' || a);

    /*����-���� �8, �� ������ ���� null �������� �� ������� ���������� [sysdate;null],
    ��������� ���������: ������� */

--    a := get_work_days (sysdate, null);
--    dbms_output.put_line ('Work days: ' || a);
end;