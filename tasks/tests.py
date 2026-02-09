from django.test import TestCase
from django.urls import reverse

from .models import Task


class TaskModelTest(TestCase):
    def test_create_task(self):
        task = Task.objects.create(title="Test task", description="A test")
        self.assertEqual(str(task), "Test task")
        self.assertFalse(task.completed)

    def test_toggle_completed(self):
        task = Task.objects.create(title="Toggle me")
        task.completed = not task.completed
        task.save()
        task.refresh_from_db()
        self.assertTrue(task.completed)


class TaskViewTest(TestCase):
    def test_task_list_empty(self):
        response = self.client.get(reverse("task_list"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "No tasks yet")

    def test_task_create(self):
        response = self.client.post(
            reverse("task_create"),
            {"title": "New task", "description": "Details"},
        )
        self.assertEqual(response.status_code, 302)
        self.assertEqual(Task.objects.count(), 1)
        self.assertEqual(Task.objects.first().title, "New task")

    def test_task_toggle(self):
        task = Task.objects.create(title="Toggle task")
        self.client.post(reverse("task_toggle", args=[task.pk]))
        task.refresh_from_db()
        self.assertTrue(task.completed)

    def test_task_delete(self):
        task = Task.objects.create(title="Delete me")
        self.client.post(reverse("task_delete", args=[task.pk]))
        self.assertEqual(Task.objects.count(), 0)
