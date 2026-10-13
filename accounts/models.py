from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=150, blank=True)
    phone = models.CharField(max_length=30, blank=True)
    avatar_url = models.URLField(blank=True, null=True)
    preferred_currency = models.CharField(max_length=10, default='INR')
    dark_mode = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    class Meta:
        indexes = [models.Index(fields=['email']), models.Index(fields=['username'])]

    def __str__(self):
        return self.full_name or self.email
