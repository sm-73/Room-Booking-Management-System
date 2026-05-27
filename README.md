# Room Booking Management System

A relational database system for managing room reservations within institutional buildings, built with PostgreSQL. The system supports structured scheduling, approval workflows, and resource tracking.



## ERD (Entity-Relationship Diagram)

![ERD](ERD_Photo.png)



## Features

- **Room Reservation**: Users can submit booking requests for one or more rooms at a specified date and time slot.
- **Approval Workflow**: Each booking is subject to review and approval by an authorized person, with a reason and status recorded.
- **Multi-room Bookings**: A single booking can be associated with multiple rooms via the `booking_room` junction table.
- **Cancellation Support**: Bookings include an `is_cancelled` flag for soft deletion.
- **Department & Role Tracking**: Each person is linked to a department and assigned a role, enabling role-based reporting.



## Database Design

The database schema was designed following normalization principles to eliminate data redundancy and ensure referential integrity. The schema consists of the following entities:

| Table | Description |
|---|---|
| `department` | Stores academic or administrative departments |
| `person` | Represents users of the system (students, staff, faculty) |
| `person_phone` | Stores phone numbers in a separate table (multi-valued attribute) |
| `building` | Contains building metadata including name and location |
| `room` | Describes rooms with their type, capacity, floor, and associated building |
| `time` | Represents time slots with date, start/end times, semester, and year |
| `booking` | Records booking requests with status, purpose, and associated person/time |
| `booking_room` | Junction table resolving the many-to-many relationship between bookings and rooms |
| `approval` | Tracks approval decisions made by authorized personnel for each booking |



## SQL Queries & Views

Several analytical queries and views were implemented to support reporting.



### View 1: `duration`
Calculates the duration of each booking based on start and end times.

```sql
CREATE VIEW duration AS
SELECT booking_id, ((T.date + T.end_time) - (T.date + T.start_time)) AS duration
FROM time T JOIN booking B ON B.time_id = T.time_id;
```



### View 2: `booking_details_view`
A comprehensive view joining all relevant tables to provide a full picture of each booking, including room, person, department, building, and time details.

```sql
CREATE VIEW booking_details_view AS
SELECT b.booking_id, b.booking_status, b.purpose,
    t.time_id, t.date AS booking_date, t.start_time AS booking_start_time, t.end_time AS booking_end_time,
    dr.duration, r.room_id, r.type AS room_type, r.capacity AS room_capacity,
    p.person_id, p.person_fname AS person_first_name, p.person_lname AS person_last_name, p.role AS person_role,
    d.dept_id AS department_id, d.dept_name AS department_name,
    bd.building_id, bd.building_name, bd.location AS building_location
FROM booking AS b
    JOIN time AS t ON b.time_id = t.time_id
    JOIN booking_room AS br ON br.booking_booking_id = b.booking_id
    JOIN room AS r ON br.room_room_id = r.room_id
    JOIN duration AS dr ON dr.booking_id = b.booking_id
    JOIN person AS p ON b.person_id = p.person_id
    JOIN building AS bd ON r.building_id = bd.building_id
    LEFT JOIN department AS d ON p.dept_id = d.dept_id;
```



### Query 3: Unique People with Approved Lecture Hall Bookings in a Given Year
Lists all unique individuals who had an approved booking for a Lecture Hall in 2025.
```sql
SELECT DISTINCT p.person_fname, p.person_lname
FROM person p
WHERE p.person_id IN (
    SELECT DISTINCT b.person_id
    FROM booking b JOIN booking_room br ON b.booking_id = br.booking_booking_id
        JOIN room r ON br.room_room_id = r.room_id
    WHERE r.type = 'Lecture Hall' AND b.booking_status = 'approved'
        AND b.time_id IN (SELECT t.time_id FROM time t WHERE t.date >= '2024-01-01' AND t.date <= '2024-12-31')
);
```



### Query 4: Buildings Ranked by Number of Approved Bookings
Finds each building's name alongside its total number of approved bookings, ordered from highest to lowest.

```sql
SELECT bu.building_name, COUNT(*) AS approved_bookings
FROM building AS bu, booking_room AS br, room AS r, booking AS bo, approval AS a
WHERE bo.booking_id = br.booking_booking_id AND br.room_room_id = r.room_id
    AND r.building_id = bu.building_id AND a.booking_id = bo.booking_id AND a.approval_status = TRUE
GROUP BY bu.building_name ORDER BY COUNT(*) DESC;
```



### Query 5: All Bookings with Requester Names
Retrieves all bookings alongside the full name of the person who made them.

```sql
SELECT p.person_fname, p.person_lname, b.*
FROM booking AS b, person AS p
WHERE b.person_id = p.person_id;
```



### Query 6: Approved Approvals with Approver Names and Booking Status
Lists all approved approvals with the approver's full name and the associated booking status.

```sql
SELECT a.*, b.booking_status, p.person_fname, p.person_lname
FROM approval AS a, booking AS b, person AS p
WHERE a.booking_id = b.booking_id AND p.person_id = a.person_id AND a.approval_status = TRUE;
```
