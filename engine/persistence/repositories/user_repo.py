from typing import Optional
from uuid import UUID
from sqlalchemy import select, update, delete
from sqlalchemy.ext.asyncio import AsyncSession
from ..models.all_models import UserModel, SecurityEvent

class UserRepo:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_id(self, id: UUID) -> Optional[UserModel]:
        result = await self.session.execute(select(UserModel).where(UserModel.id == str(id)))
        return result.scalars().first()

    async def get_by_email(self, email: str) -> Optional[UserModel]:
        result = await self.session.execute(select(UserModel).where(UserModel.email == email))
        return result.scalars().first()

    async def create(self, display_name: str, email: str, password_hash: str, recovery_hash: str, password_salt_hex: str, wrapped_key_hex: str) -> str:
        user = UserModel(
            display_name=display_name,
            email=email,
            password_hash=password_hash,
            recovery_hash=recovery_hash,
            password_salt_hex=password_salt_hex,
            wrapped_key_hex=wrapped_key_hex
        )
        self.session.add(user)
        await self.session.flush()
        return str(user.id)

    async def update_login_failure(self, user_id: str, failed_attempts: int, is_locked: bool, lock_until) -> None:
        await self.session.execute(
            update(UserModel)
            .where(UserModel.id == user_id)
            .values(failed_attempts=failed_attempts, is_locked=is_locked, lock_until=lock_until)
        )
        await self.session.flush()

    async def reset_lockout(self, user_id: str) -> None:
        await self.session.execute(
            update(UserModel)
            .where(UserModel.id == user_id)
            .values(failed_attempts=0, is_locked=False, lock_until=None)
        )
        await self.session.flush()

    async def update_credentials(self, user_id: str, password_hash: str, password_salt_hex: str, wrapped_key_hex: str) -> None:
        await self.session.execute(
            update(UserModel)
            .where(UserModel.id == user_id)
            .values(
                password_hash=password_hash,
                password_salt_hex=password_salt_hex,
                wrapped_key_hex=wrapped_key_hex
            )
        )
        await self.session.flush()

    async def update_lockout_state(self, user_id: str, locked: bool, until) -> None:
        await self.session.execute(
            update(UserModel)
            .where(UserModel.id == user_id)
            .values(is_locked=locked, lock_until=until)
        )
        await self.session.flush()

    async def delete_user(self, user_id: str) -> None:
        await self.session.execute(delete(UserModel).where(UserModel.id == user_id))
        await self.session.flush()

    async def list_local_profiles(self) -> list[dict]:
        result = await self.session.execute(select(UserModel.id, UserModel.display_name, UserModel.email, UserModel.created_at))
        return [
            {"id": str(row.id), "display_name": row.display_name, "email": row.email, "created_at": row.created_at}
            for row in result.all()
        ]

    async def record_security_event(self, event_type: str, user_id: str, details: Optional[dict] = None) -> None:
        event = SecurityEvent(event_type=event_type, user_id=user_id, details=details)
        self.session.add(event)
        await self.session.flush()
