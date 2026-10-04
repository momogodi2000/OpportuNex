import asyncio
from datetime import datetime
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
import logging

logger = logging.getLogger(__name__)

class BackupService:
    @staticmethod
    async def create_backup(source: str) -> None:
        logger.info(f"Creating backup from source: {source}")

class LocalNotifier:
    @staticmethod
    async def send_reminder(message: str) -> None:
        logger.info(f"Sending reminder: {message}")

class MonitorService:
    @staticmethod
    async def get_active_monitors(now: datetime) -> list:
        return []
    
    @staticmethod
    async def run_search_pipeline(monitor_id: str, event_bus: any) -> None:
        logger.info(f"Running search pipeline for monitor {monitor_id}")

class ReminderService:
    @staticmethod
    async def get_due_reminders() -> list:
        return []

scheduler = AsyncIOScheduler()

async def run_weekly_backup() -> None:
    """Calls BackupService.create_backup('scheduler')"""
    logger.info("Starting weekly backup")
    try:
        await BackupService.create_backup('scheduler')
    except Exception as e:
        logger.error(f"Weekly backup failed: {e}")

async def check_deadline_reminders() -> None:
    """Queries reminders due today, sends via local_notifier"""
    logger.info("Checking deadline reminders")
    try:
        due_reminders = await ReminderService.get_due_reminders()
        for reminder in due_reminders:
            await LocalNotifier.send_reminder(f"Deadline approaching: {reminder}")
    except Exception as e:
        logger.error(f"Deadline reminders failed: {e}")

async def run_due_monitors(event_bus: any = None) -> None:
    """For each active monitor where next_run_at <= now, runs the search pipeline"""
    logger.info("Running due monitors")
    try:
        now = datetime.utcnow()
        due_monitors = await MonitorService.get_active_monitors(now)
        for monitor in due_monitors:
            await MonitorService.run_search_pipeline(monitor['id'], event_bus)
    except Exception as e:
        logger.error(f"Running due monitors failed: {e}")

def setup_scheduler(event_bus: any = None) -> None:
    # Weekly backup: every Sunday at 2:00 AM
    scheduler.add_job(
        run_weekly_backup,
        CronTrigger(day_of_week='sun', hour=2, minute=0),
        id='weekly_backup',
        replace_existing=True,
    )
    
    # Deadline reminders: every day at 8:00 AM  
    scheduler.add_job(
        check_deadline_reminders,
        CronTrigger(hour=8, minute=0),
        id='deadline_reminders',
        replace_existing=True,
    )
    
    # Active monitors: checked every 15 minutes, runs those due
    scheduler.add_job(
        run_due_monitors,
        CronTrigger(minute='*/15'),
        args=[event_bus],
        id='monitor_check',
        replace_existing=True,
    )
    
    scheduler.start()
    logger.info("Scheduler started")
