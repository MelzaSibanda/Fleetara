from rest_framework.permissions import BasePermission


class IsOwner(BasePermission):
    """Only users with role = owner can access."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'owner'


class IsOwnerOrAdmin(BasePermission):
    """Owner or admin can access."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in ['owner', 'admin']


class IsFleetManager(BasePermission):
    """Fleet manager, admin, or owner."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in ['owner', 'admin', 'fleet_manager']


class IsDriver(BasePermission):
    """Only drivers."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'driver'


class IsDriverOrManager(BasePermission):
    """Drivers, fleet managers, admins, and owners."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [
            'driver', 'fleet_manager', 'admin', 'owner'
        ]
