import discord
import json
import os
import random
import string
from discord.ext import commands

intents = discord.Intents.default()
intents.message_content = True
intents.members = True

bot = commands.Bot(command_prefix='!', intents=intents)

# Файл для хранения ключей
KEYS_FILE = 'keys.json'

# Загрузить ключи из файла
def load_keys():
    if os.path.exists(KEYS_FILE):
        with open(KEYS_FILE, 'r') as f:
            return json.load(f)
    return {}

# Сохранить ключи
def save_keys(keys):
    with open(KEYS_FILE, 'w') as f:
        json.dump(keys, f, indent=4)

keys_db = load_keys()

@bot.event
async def on_ready():
    print(f'✅ Бот запущен как {bot.user}')
    print(f'ID бота: {bot.user.id}')

# Команда для генерации ключа
@bot.command()
@commands.has_permissions(administrator=True)
async def gen(ctx, user: discord.User, days: int = 30):
    # Генерируем ключ
    key = ''.join(random.choices(string.ascii_uppercase + string.digits, k=12))
    key = f"ZV-{key}"
    
    # Сохраняем
    keys_db[key] = {
        'owner': user.id,
        'hwid': None,
        'expires': days,
        'used': False
    }
    save_keys(keys_db)
    
    embed = discord.Embed(
        title="✅ Ключ создан",
        description=f"**Ключ:** `{key}`\n**Для:** {user.mention}\n**Срок:** {days} дней",
        color=discord.Color.green()
    )
    await ctx.send(embed=embed)
    
    # Отправляем в личку
    try:
        await user.send(f"🎫 Твой ключ для скрипта: `{key}`\nСрок: {days} дней")
    except:
        pass

# Команда для проверки ключей
@bot.command()
@commands.has_permissions(administrator=True)
async def keys(ctx):
    if not keys_db:
        await ctx.send("❌ Нет ключей")
        return
    
    text = "**📋 Список ключей:**\n"
    for key, data in list(keys_db.items())[:10]:
        status = "✅ Использован" if data['used'] else "❌ Не использован"
        owner = bot.get_user(data['owner'])
        owner_name = owner.name if owner else "Неизвестно"
        hwid = data['hwid'] if data['hwid'] else "Не привязан"
        text += f"`{key}` | {status} | {owner_name} | HWID: {hwid}\n"
    
    await ctx.send(text)

# Команда для удаления ключа
@bot.command()
@commands.has_permissions(administrator=True)
async def delkey(ctx, key: str):
    if key in keys_db:
        del keys_db[key]
        save_keys(keys_db)
        await ctx.send(f"✅ Ключ {key} удалён")
    else:
        await ctx.send("❌ Ключ не найден")

# 👇👇👇 СЮДА ВСТАВЛЯЕШЬ ТОКЕН 👇👇👇
bot.run('')