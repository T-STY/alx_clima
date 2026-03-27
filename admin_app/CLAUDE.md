# ALX-Clima Admin App

## Purpose
Administrative dashboard for ALX-Clima HVAC business. Used by the technician/owner to manage appointments, clients, equipment catalog, scheduling, and company settings. Connects to the same Firebase project as the client app.

## Design Language
- Glassmorphic elevated cards with blur effects and translucent backgrounds
- Floating card aesthetic inspired by iOS 18 / visionOS
- Rich gradients as accent backgrounds behind key content
- Elevated shadows with colored tints (not flat gray)
- Navigation: 5-tab bottom bar (Panel, Citas, Catálogo, Clientes, Ajustes) — NO theme toggle in nav bar
- Theme toggle (light/dark) lives in Settings page, persisted via SharedPreferences
- Font: Exo 2 via Google Fonts
- Icons: Iconsax exclusively
- All text in Spanish

## Code Rules
- Zero comments in code
- Use `withValues(alpha: x)` not `withOpacity(x)`
- No file over 300 lines — split into helper files
- Trailing commas on multi-line parameters
- Use `const` constructors where possible
- Use `Theme.of(context)` for dynamic light/dark colors
- AdminTheme static colors for accents: primaryColor, secondaryColor, accentColor, errorColor, successColor, warningColor

## Firebase Collections

### appointments (global)
Each document represents one booking (may include multiple equipment):
- `appointmentId`: unique string
- `userId`: Firebase Auth UID of the client
- `status`: pending | confirmed | completed | cancelled | modified
- `date`: "yyyy-MM-dd" string
- `timeSlots`: list of hour strings booked (e.g. ["09:00 - 10:00", "10:00 - 11:00"])
- `timeSlotDisplay`: human-readable time range
- `serviceType`: maintenance | installation | removal | relocation
- `serviceTypeDisplay`: Spanish display name
- `notes`: optional text from client
- `createdAt`: Firestore timestamp
- `equipmentCount`: number of equipment in this appointment
- `customer`: map with name, phone, email, address
- `equipment`: list of maps, each with id, name, brand, btuCapacity, location, type
- `totalUserEquipment`: total equipment the user has registered

### schedule/{date}
- `slots`: list of available time strings (e.g. ["09:00 - 10:00", "10:00 - 11:00"])
- Date is the document ID in "yyyy-MM-dd" format
- Slots are removed when booked, restored (sorted) when cancelled

### bookedSlots
- `date`, `slot`, `userId`, `bookedAt`
- Tracks which slots are taken to prevent double-booking

### quoteCatalog
Equipment available for purchase through the app:
- `name`: model name
- `brand`: manufacturer
- `type`: miniSplit | centralAC | heatPump
- `btuCapacity`: integer
- `price`: double (approximate)
- `description`: optional product description
- `manufacturerWarrantyDetails`: warranty text

### equipmentCatalog
Brands and their models (used in dropdowns throughout the app):
- `name`: brand name (e.g. "Mirage")
- `models`: list of model name strings
- `order`: sort order (lower = first, Mirage should be first)

### config/equipmentTypes
- `types`: list of equipment type strings (e.g. ["Mini Split", "AC Central"])

### config/pricing
Installation pricing pulled by the client app:
- `installOnly`: map of BTU to price (e.g. {"12000": 700, "18000": 850})
- `fullPackage`: map of BTU to price for equipment+installation
- `secondFloorSurcharge`: multiplier (e.g. 0.3 = 30% extra)
- `differentFloorSurcharge`: multiplier
- `multiUnitDiscount`: discount for 2+ units (e.g. 0.1 = 10% off)

### config/workSchedule
- `workDays`: list of weekday integers (1=Mon, 7=Sun)
- `startHour`: integer (e.g. 9)
- `endHour`: integer (e.g. 18)

### company/info
- `name`, `phone`, `whatsApp`, `email`, `businessHours`, `techWarranty`

### users/{uid}
Client profiles with subcollections:
- Profile fields: name, phone, email, street, exteriorNumber, interiorNumber, colonia, city, postalCode, state, memberSince, suspended (boolean)
- `users/{uid}/equipment/` — client's registered equipment
- `users/{uid}/serviceHistory/` — completed service records
- `users/{uid}/notifications/` — in-app notifications (type, title, message, createdAt, read)

## Admin App Screens

### 1. Dashboard (Panel)
- 4 stat counters: today's appointments, pending, confirmed, completed
- Recent appointments list (last 8) showing client name, date, service type, status
- Real-time via StreamBuilder on appointments collection

### 2. Appointments (Citas)
- Filterable list: all, pending, confirmed, completed, cancelled
- Each appointment shows: status indicator, client name, date/time, service type, equipment summary
- Tap to view full detail: client info (name, phone, email, address), date/time, service type, notes, all equipment listed
- Actions per status:
  - Pending: Confirmar, Reagendar, Cancelar
  - Confirmed: Completar, Cancelar
  - Completed/Cancelled: Eliminar
- **Confirmar**: updates status to 'confirmed'
- **Reagendar**: shows available dates from schedule collection, admin picks new date + time slot, old appointment cancelled (slots restored sorted), new appointment created as confirmed, notification sent to client via users/{uid}/notifications
- **Cancelar**: updates status to 'cancelled', restores time slots to schedule collection (merge + sort), removes from bookedSlots
- **Completar**: updates status to 'completed', writes service record to users/{uid}/serviceHistory for each equipment in the appointment
- **Eliminar**: deletes the Firestore document

### 3. Schedule (Horarios) — merged into Settings or standalone
- Configure work days (toggle Mon-Sun)
- Set start hour and end hour
- Set how many days ahead to generate
- Generate button: creates schedule/{date} docs with 1-hour slots for each work day
- View existing scheduled dates
- Tap a date to edit: add/remove individual time slots, save updates

### 4. Catalog (Catálogo)
- **Equipment list**: StreamBuilder on quoteCatalog ordered by brand. Shows brand, model name, BTU, price. Tap to edit (price, description, warranty). Delete option.
- **Add equipment**: bottom sheet with brand dropdown (from equipmentCatalog), model dropdown (filtered by selected brand), BTU selection (12K/18K/24K/36K), price field, warranty field (prefilled with default text), optional description
- **Brands & Models**: StreamBuilder on equipmentCatalog. View brands with their models. Add new brand (name + comma-separated models + sort order). Tap to edit existing brand (add/remove individual models).
- **Equipment Types**: StreamBuilder on config/equipmentTypes. Add/remove type strings displayed as chips.

### 5. Clients (Clientes)
- Searchable list of all users from users collection
- Each client shows: name, phone, suspended status
- Tap for detail: full profile info, suspend/reactivate toggle, equipment list (real-time stream from users/{uid}/equipment with delete capability), add equipment to client's profile
- **Suspend**: sets users/{uid}.suspended = true — client app checks this and blocks access, showing suspended screen
- **Reactivate**: sets suspended = false — client regains access in real-time

### 6. Settings (Ajustes)
- **Company info**: name, phone, WhatsApp, email, business hours, technician warranty text — loads from and saves to company/info
- **Pricing**: install-only prices per BTU, full-package prices per BTU, second floor surcharge, different floor surcharge, multi-unit discount — loads from and saves to config/pricing
- **Theme toggle**: light/dark mode switch, persisted via SharedPreferences
- **Work Schedule**: configure work days, hours, generation (can be here or separate screen)
