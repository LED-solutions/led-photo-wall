# LED Photo Wall

Guests scan a QR code, send photos from their phone, you approve them, and they appear live on the LED screen. Made for weddings and galas, played through **OBS** (Browser Source) → HDMI → **VX processor** → LED wall.

### 👉 [Preview the screen with sample photos](https://led-solutions.github.io/led-photo-wall/screen.html?demo=1)

No account needed for the preview. Change the style by adding `&mode=mosaic`, `&mode=polaroid`, `&mode=slideshow` or `&mode=overlay` to the link.

---

## How it works

| Page | Who uses it | Link |
|---|---|---|
| **Guest page** | Guests, from the QR code | `led-solutions.github.io/led-photo-wall/?e=amine-sarra` |
| **Moderator page** | You / the organizer, on a phone or laptop | `led-solutions.github.io/led-photo-wall/admin.html` |
| **Screen page** | OBS Browser Source | `led-solutions.github.io/led-photo-wall/screen.html?e=amine-sarra` |

1. The guest scans the QR, picks up to 5 photos, adds their name and a message (optional). The page is in **French, English and Arabic**.
2. The photo is shrunk on the phone before sending (max 1920 px), so it uploads fast on 4G.
3. It arrives in **To approve** on the moderator page. You tap **Approve** or **Reject**.
4. Approved photos appear on the screen within a second or two, no refresh.

Photos are stored in **Supabase** (online storage + database), so the OBS PC only needs internet.

## Screen styles

Change them live from the moderator page; OBS follows automatically.

| Style | What the screen shows |
|---|---|
| **Spotlight** | One photo at a time, full screen. New photos come in with a "New photo" badge and stay longer. |
| **Slideshow** | One photo at a time, in order, no badge. |
| **Mosaic** | A grid of photos (up to 12), one tile changing every few seconds. New photos pop up big first. The QR code takes the last tile. |
| **Polaroid** | Photos drop onto the screen like printed polaroids with the guest's name and message. |
| **Overlay** | Transparent background: new photos slide into a corner **on top of the live camera** in OBS. |

Portrait phone photos on a landscape screen are shown sharp in the middle, with a blurred copy filling the sides (no black bars).

## Moderator page

- **Approve / Reject** new photos, or **Approve all**
- **⭐ Show now**: puts a photo on the screen right away
- **Hide**: removes a photo from the screen
- **Auto-approve**: photos go straight to the screen (no moderation)
- **Guests can upload**: close uploads at the end of the event
- **QR code on the screen**: show or hide it
- **Download all photos (ZIP)**: every approved photo + a `messages.txt` with names and messages, to give to the couple
- QR code as a PNG for table cards, and copy buttons for the OBS links

---

## One-time setup (about 10 minutes)

### 1. Create the Supabase project
Go to [supabase.com](https://supabase.com), create an account and a **New project** (any name, e.g. `led-photo-wall`; choose a region close to Tunisia, e.g. Frankfurt or Paris).

### 2. Run the setup script
In the project: **SQL Editor → New query**, paste everything from [`setup.sql`](setup.sql), click **Run**. It creates the tables, the security rules, the `photos` storage and live updates.

### 3. Connect the pages
In Supabase: **Project Settings → API** (or the **Connect** button). Copy the **Project URL** and the **anon public** key (or **publishable** key) into [`config.js`](config.js):

```js
window.PHOTOWALL_CONFIG = {
  SUPABASE_URL: 'https://xxxxxxxx.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOi...'
};
```

These two values are safe to publish: the rules from step 2 decide what guests can do.

### 4. Create your moderator account
- **Authentication → Users → Add user → Create new user**: your email + a password (tick *Auto Confirm User*).
- Back in the **SQL Editor**, run (with your email):
  ```sql
  insert into public.admins (user_id) select id from auth.users where email = 'you@example.com';
  ```
- Recommended: **Authentication → Sign In / Providers → Email** → turn off **Allow new users to sign up**.

### 5. First event
Open `admin.html`, sign in, tap **+ New event**, write the names (e.g. *Amine & Sarra*) and the date. The links and the QR code are ready.

---

## Event day

**OBS**
1. **Sources → + → Browser**, paste the **full screen** link from the moderator page.
2. Width and height = your LED canvas in pixels (the VX output size, e.g. 1920 × 1080).
3. Untick **Shutdown source when not visible**, so the wall keeps running when you switch scenes.
4. For photos on top of the live camera: add a second Browser source with the **overlay** link above the camera source.

**Checklist**
- Internet for the OBS PC (a 4G router if the venue Wi-Fi is weak). Guests use their own mobile data.
- QR code on the screen, plus printed on table cards (download the PNG).
- Test before guests arrive: send a photo from your own phone and approve it.
- At the end: turn off **Guests can upload**, then **Download all photos (ZIP)** for the couple.

## How many photos?

- Each photo is about 300–500 KB after shrinking, so **1 GB holds about 2,500 photos**. Check your Supabase plan's storage limit; a normal wedding uses a few hundred photos.
- The screen only loads the next few photos at a time, so it stays smooth with 50 or 2,000 photos.
- Old events can be deleted from Supabase (**Table Editor → events**, and the event's folder in **Storage → photos**) to free space.

## Screen link options

Add these to the screen link (after `?e=your-event`):

| Option | Effect |
|---|---|
| `&mode=mosaic` | Force a style (`spotlight`, `slideshow`, `mosaic`, `polaroid`, `overlay`) instead of following the moderator page |
| `&t=10` | Seconds per photo in spotlight/slideshow (default 7) |
| `&lang=en` | Screen text in `fr` (default), `en` or `ar` |
| `&qr=0` / `&qr=1` | Hide / show the QR code |
| `&title=0` | Hide the names in the corner |
| `&bg=transparent` | Transparent background (default in overlay) |
| `&corner=bl` | Overlay corner: `br`, `bl`, `tr`, `tl` |
| `&tiles=9` | Max photos in the mosaic (default 12) |
| `&demo=1` | Sample photos, no Supabase needed |

## Files

| File | What it is |
|---|---|
| [`index.html`](index.html) | Guest page |
| [`admin.html`](admin.html) | Moderator page |
| [`screen.html`](screen.html) | Screen page for OBS |
| [`app.js`](app.js) | Shared helpers |
| [`config.js`](config.js) | Your Supabase URL and key |
| [`setup.sql`](setup.sql) | One-time database setup |

---

Made by **Mohamed Seif Eddine Mannai** · part of [LED-solutions](https://github.com/LED-solutions).
