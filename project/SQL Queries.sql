select * from department
select * from person
select * from person_phone
select * from building
select * from room
select * from time
select * from booking
select * from approval
select * from booking_room

--Query 1: Calculating duration of each booking
create view duration as 
select booking_id, ((T.date + T.end_time) - (T.date + T.start_time) ) AS duration
from time T join booking B on B.time_id=T.time_id

-- check the view
select * from duration

--Query 2: Creating a usage report for rooms
CREATE VIEW booking_details_view AS
SELECT
    b.booking_id, b.booking_status, b.purpose,
    t.time_id, t.date AS booking_date, t.start_time AS booking_start_time, t.end_time AS booking_end_time,
	dr.duration,
    r.room_id, r.type AS room_type,r.capacity AS room_capacity,
    p.person_id, p.person_fname AS person_first_name, p.person_lname AS person_last_name, p.role AS person_role,
    d.dept_id AS department_id, d.dept_name AS department_name,
	bd.building_id, building_name, bd.location AS building_location
	
FROM booking AS b JOIN time AS t ON b.time_id = t.time_id
	
JOIN booking_room AS br ON br.booking_booking_id = b.booking_id

JOIN room AS r ON br.room_room_id = r.room_id 

JOIN duration as dr on dr.booking_id=b.booking_id

JOIN person AS p ON b.person_id = p.person_id

JOIN building AS bd ON r.building_id = bd.building_id

LEFT JOIN department AS d ON p.dept_id = d.dept_id;

--check the view
select * from booking_details_view;


--query 3: Listing all unique people with a Approved booking for a 'Classroom' in 2025
SELECT DISTINCT p.person_fname,  p.person_lname
FROM person p 
WHERE p.person_id IN (

        SELECT DISTINCT b.person_id 
        FROM  booking b JOIN booking_room br ON b.booking_id = br.booking_booking_id 
        JOIN room r ON br.room_room_id = r.room_id 
        WHERE
		r.type = 'Lecture Hall' AND b.booking_status = 'approved' AND b.time_id IN (
		
          		SELECT t.time_id
		  		FROM time t 
		   		WHERE t.date >= '2024-01-01' AND t.date <= '2024-12-31'
            )
    );

--Query 4: Find each building's name alongside its number of approved bookings.

select Bu.building_name, count(*)
from Building as Bu, Booking_Room as BR, Room as R, Booking as Bo, Approval as A
where bo.booking_id = br.booking_booking_id and br.room_room_id = r.room_id
and r.building_id = bu.building_id and a.booking_id = bo.booking_id and a.approval_status = true
group by bu.building_name
order by count(*) desc;


--Query 5: Find all the bookings with the name of each person who made them

select p.person_fname, p.person_lname, b.*
from booking as b, person as p
where b.person_id = p.person_id;


--Query 6: Find all approvals, name of who approved them and their booking status

select a.*, b.booking_status, p.person_fname, p.person_lname
from approval as a, booking as b, person as p
where a.booking_id = b.booking_id and p.person_id = a.person_id and a.approval_status = true;