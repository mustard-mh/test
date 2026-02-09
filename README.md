# Django Task Manager

A simple Django example project — a task manager with CRUD operations.

## Setup

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Open http://localhost:8000 to view the app.

## Running Tests

```bash
python manage.py test
```

## Create Admin User

```bash
python manage.py createsuperuser
```

Then visit http://localhost:8000/admin/.
