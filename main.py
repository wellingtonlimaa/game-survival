import asyncio
import array
import json
import math
import os
import random
from pathlib import Path
from dataclasses import dataclass

import pygame


WIDTH, HEIGHT = 960, 540
WORLD_W, WORLD_H = 3000, 2100
TILE_SIZE = 32
MAP_COLS = math.ceil(WORLD_W / TILE_SIZE)
MAP_ROWS = math.ceil(WORLD_H / TILE_SIZE)
FPS = 60
MAX_ENEMIES = 220
GOAL_OPTIONS = (600, 900, 1800)
SAVE_FILE = "savegame.json"
SAVE_SLOT_FILES = ["savegame_slot1.json", "savegame_slot2.json", "savegame_slot3.json"]
ASSET_DIR = Path(__file__).resolve().parent / "assets"
DIFFICULTIES = {
    "facil": ("Facil", 0.82, 0.85, 1.15),
    "normal": ("Normal", 1.0, 1.0, 1.0),
    "dificil": ("Dificil", 1.22, 1.18, 0.9),
    "infernal": ("Infernal", 1.55, 1.42, 0.78),
}

BG = (13, 15, 22)
PANEL = (25, 30, 42)
TEXT = (232, 238, 247)
MUTED = (142, 153, 174)
RED = (234, 86, 86)
GREEN = (85, 214, 128)
GOLD = (248, 198, 83)
CYAN = (82, 190, 255)
VIOLET = (171, 123, 255)
ORANGE = (255, 143, 82)
PINK = (255, 103, 166)

RARITIES = {
    "comum": {"color": MUTED, "mult": 1.0},
    "raro": {"color": CYAN, "mult": 1.35},
    "epico": {"color": VIOLET, "mult": 1.75},
    "lendario": {"color": GOLD, "mult": 2.3},
}

WEAPON_INFO = {
    "wand": ("Varinha", "Dispara no inimigo mais proximo"),
    "orbit": ("Aura", "Circulos de energia giram ao redor"),
    "knife": ("Facas", "Rajada na direcao do movimento"),
    "axe": ("Machado", "Lamina pesada atravessa hordas"),
    "lightning": ("Raio", "Atinge inimigos aleatorios"),
    "bomb": ("Bomba", "Explode grupos proximos"),
    "drone": ("Drone", "Companheiro que dispara sozinho"),
    "spear": ("Lanca", "Perfura em linha reta"),
    "book": ("Livro", "Paginas magicas orbitam e cortam"),
    "flame": ("Fogo", "Anel de chamas em area"),
    "scythe": ("Foice", "Golpe amplo no inimigo mais proximo"),
    "chain": ("Corrente", "Salta entre alvos proximos"),
    "boomerang": ("Bumerangue", "Vai e volta atravessando inimigos"),
}

EVOLUTION_INFO = {
    "wand": ("Estrela Guia", "Projeteis perseguem alvos proximos"),
    "orbit": ("Aura Astral", "Orbes maiores giram por mais tempo"),
    "knife": ("Tempestade de Facas", "Dispara tambem uma rajada lateral"),
    "axe": ("Machado Vulcanico", "Impactos criam pequenas explosoes"),
    "lightning": ("Cadeia Celeste", "Raios saltam para inimigos vizinhos"),
    "bomb": ("Carga Tripla", "Lanca tres bombas em leque"),
    "drone": ("Enxame Drone", "Drones disparam tiros duplos"),
    "spear": ("Lanca Cometa", "Projeteis mais largos e perfurantes"),
    "book": ("Grimorio Vivo", "Paginas duram mais e giram mais longe"),
    "flame": ("Sol Interior", "Cria explosoes secundarias ao redor"),
    "scythe": ("Ceifadora Lunar", "Dispara tres laminas amplas"),
    "chain": ("Corrente Tempestade", "Cada salto causa choque em area"),
    "boomerang": ("Disco Retornante", "Bumerangues voltam mais fortes e maiores"),
}

PASSIVE_INFO = {
    "move": ("Botas", "Velocidade de movimento"),
    "regen": ("Regeneracao", "Recupera vida aos poucos"),
    "magnet": ("Ima", "Atrai XP de mais longe"),
    "armor": ("Armadura", "Reduz dano recebido"),
    "luck": ("Sorte", "Melhora raridade dos upgrades"),
    "cooldown": ("Ampulheta", "Reduz recarga das armas"),
}

PERMANENT_UPGRADES = {
    "max_hp": ("Vida", "+8 vida inicial", 70),
    "damage": ("Dano", "+4% dano", 90),
    "xp_gain": ("Sabedoria", "+5% XP", 80),
    "move": ("Agilidade", "+6 velocidade", 65),
    "luck": ("Sorte", "+4% sorte", 100),
    "armor": ("Defesa", "+0.4 armadura", 85),
    "magnet": ("Coleta", "+10 alcance de coleta", 75),
    "rerolls": ("Estrategia", "+1 reroll a cada 3 niveis", 110),
}

TALENTS = {
    "survival": ("Sobrevivencia", "+12 vida e +0.08 regen", 1),
    "weaponry": ("Arsenal", "+6% dano", 1),
    "collector": ("Coletor", "+18 alcance de coleta", 1),
    "fortune": ("Fortuna", "+8% sorte", 1),
    "tempo": ("Tempo", "-3% cooldown", 1),
    "growth": ("Crescimento", "+4% XP e moedas", 1),
    "planning": ("Planejamento", "+1 banimento a cada 2 niveis", 1),
}

CHARACTERS = {
    "hunter": ("Cacador", "Equilibrado", {"hp": 0, "speed": 0, "damage": 0, "luck": 0}),
    "knight": ("Guardiao", "Mais vida e armadura", {"hp": 35, "speed": -18, "damage": 0.04, "armor": 3}),
    "mage": ("Arcanista", "Mais dano e sorte", {"hp": -10, "speed": 0, "damage": 0.12, "luck": 0.25}),
    "rogue": ("Ladina", "Rapida e fragil", {"hp": -18, "speed": 36, "damage": 0.04, "luck": 0.1}),
    "alchemist": ("Alquimista", "Explosoes melhores", {"hp": 8, "speed": 0, "damage": 0.08, "luck": 0.18}),
    "monk": ("Monge", "Regenera e coleta longe", {"hp": 12, "speed": 8, "regen": 0.35, "pickup": 42}),
}

RELIC_INFO = {
    "blood_crown": ("Coroa Rubra", "+18% dano, -12 vida maxima"),
    "moon_shard": ("Fragmento Lunar", "+25% XP e +15% sorte"),
    "phoenix_ember": ("Brasa Fenix", "Cura forte e +0.35 regeneracao"),
    "storm_ring": ("Anel da Tempestade", "Raios extras por alguns segundos"),
    "giant_belt": ("Cinto Gigante", "+35 vida e +2 armadura"),
}

CHARACTER_OBJECTIVES = {
    "hunter": ("Faca 120 KOs em uma partida", 90),
    "knight": ("Derrote um chefe", 120),
    "mage": ("Evolua uma arma", 140),
    "rogue": ("Sobreviva 5 minutos", 110),
    "alchemist": ("Colete 300 moedas na partida", 130),
    "monk": ("Alcance nivel 12", 130),
}

ACHIEVEMENTS = {
    "first_blood": ("Primeira queda", "Derrote 1 inimigo", 25),
    "hundred_kills": ("Cem na noite", "Derrote 100 inimigos no total", 80),
    "five_hundred_kills": ("Colheita sombria", "Derrote 500 inimigos no total", 160),
    "boss_down": ("Queda do chefe", "Derrote um chefe", 120),
    "boss_hunter": ("Cacador de chefes", "Derrote 5 chefes no total", 240),
    "survivor_5": ("Cinco minutos", "Sobreviva 5 minutos", 100),
    "survivor_10": ("Dez minutos", "Sobreviva 10 minutos", 220),
    "evolved": ("Forma final", "Evolua uma arma", 150),
    "synergy": ("Maestria combinada", "Ative uma sinergia", 150),
    "rich": ("Bolso pesado", "Ganhe 500 moedas no total", 180),
    "wealthy": ("Tesouro guardado", "Ganhe 1500 moedas no total", 320),
}

SYNERGIES = {
    "storm_mage": ("Mago da Tempestade", {"lightning", "chain"}, "+12% dano e raios mais frequentes"),
    "pyromancer": ("Piromante", {"flame", "bomb"}, "+18% dano de explosao"),
    "blade_dancer": ("Danca das Laminas", {"knife", "scythe"}, "+10% velocidade e dano"),
    "orbit_master": ("Mestre Orbital", {"orbit", "book"}, "+22 alcance de coleta"),
    "ranger": ("Patrulheiro", {"spear", "boomerang"}, "+1 perfuracao para armas precisas"),
}

MAP_MODIFIERS = {
    "blood_moon": ("Lua Sangrenta", "Mais elites e mais moedas"),
    "gold_rush": ("Corrida do Ouro", "Mais moedas, inimigos mais rapidos"),
    "glass_night": ("Noite de Vidro", "Mais dano causado e recebido"),
    "calm": ("Noite Calma", "Sem modificador especial"),
}

NARRATIVE_LINES = [
    "Um sino distante toca sob a neblina.",
    "As ruinas sussurram nomes antigos.",
    "O vento muda: algo observa a arena.",
    "Uma estrela cai atras das arvores.",
    "O chao pulsa como se respirasse.",
]


def clamp(value, low, high):
    return max(low, min(high, value))


def length(x, y):
    return math.hypot(x, y)


def norm(x, y):
    mag = length(x, y)
    if mag == 0:
        return 0, 0
    return x / mag, y / mag


def draw_text(surface, font, text, pos, color=TEXT, center=False):
    image = font.render(text, True, color)
    rect = image.get_rect()
    if center:
        rect.center = pos
    else:
        rect.topleft = pos
    surface.blit(image, rect)
    return rect


@dataclass
class Player:
    x: float = WORLD_W * 0.25
    y: float = WORLD_H * 0.25
    radius: int = 17
    speed: float = 245
    hp: float = 110
    max_hp: float = 110
    xp: int = 0
    xp_to_level: int = 16
    level: int = 1
    damage_mult: float = 1
    cooldown_mult: float = 1
    pickup_radius: float = 92
    armor: float = 0
    regen: float = 0
    luck: float = 0
    invuln: float = 0
    last_dx: float = 1
    last_dy: float = 0
    aim_x: float = WORLD_W * 0.25 + 160
    aim_y: float = WORLD_H * 0.25
    aim_dx: float = 1
    aim_dy: float = 0


@dataclass
class Weapon:
    key: str
    level: int
    cooldown: float
    timer: float = 0
    evolved: bool = False


@dataclass
class Enemy:
    x: float
    y: float
    radius: int
    hp: float
    speed: float
    damage: float
    xp: int
    kind: str
    elite: bool = False
    cooldown: float = 0
    windup: float = 0
    windup_total: float = 0
    target_x: float = 0
    target_y: float = 0
    hit_flash: float = 0
    knock_x: float = 0
    knock_y: float = 0


@dataclass
class Projectile:
    x: float
    y: float
    vx: float
    vy: float
    radius: int
    damage: float
    ttl: float
    pierce: int
    color: tuple
    kind: str = "bolt"
    explode_radius: float = 0
    source: str = ""
    angle: float = 0
    orbit_radius: float = 0
    hit_cd: float = 0


@dataclass
class Gem:
    x: float
    y: float
    value: int
    radius: int = 6
    kind: str = "xp"


@dataclass
class Chest:
    x: float
    y: float
    radius: int = 14


@dataclass
class Obstacle:
    x: float
    y: float
    radius: int
    kind: str
    color: tuple


@dataclass
class Breakable:
    x: float
    y: float
    radius: int
    hp: float
    kind: str
    color: tuple


@dataclass
class TerrainDetail:
    x: float
    y: float
    kind: str
    color: tuple
    size: int


@dataclass
class Altar:
    x: float
    y: float
    radius: int
    kind: str
    active: bool = True


@dataclass
class Merchant:
    x: float
    y: float
    radius: int = 22
    active: bool = True


@dataclass
class Portal:
    x: float
    y: float
    radius: int = 26
    active: bool = True


@dataclass
class Pet:
    x: float
    y: float
    cooldown: float = 0


@dataclass
class Particle:
    x: float
    y: float
    vx: float
    vy: float
    ttl: float
    color: tuple
    radius: float


@dataclass
class DamageText:
    x: float
    y: float
    text: str
    ttl: float
    color: tuple


@dataclass
class VisualEffect:
    x: float
    y: float
    ttl: float
    duration: float
    kind: str
    color: tuple
    radius: float = 40


class Game:
    def __init__(self):
        pygame.mixer.pre_init(44100, -16, 1, 512)
        pygame.init()
        pygame.display.set_caption("Noite dos Sobreviventes")
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        self.clock = pygame.time.Clock()
        self.font = pygame.font.Font(None, 28)
        self.big_font = pygame.font.Font(None, 62)
        self.small_font = pygame.font.Font(None, 22)
        self.assets = self.create_visual_assets()
        self.scaled_cache = {}
        self.audio_enabled = False
        self.sounds = {}
        self.sound_cooldowns = {}
        self.setup_audio()
        self.save_slot = 1
        self.progress = self.load_progress()
        self.selected_character = self.progress.get("selected_character", "hunter")
        self.difficulty = self.progress.get("difficulty", "normal")
        self.apply_audio_settings()
        self.reset()
        self.state = "menu"

    def default_progress(self):
        return {
            "coins": 0,
            "total_coins": 0,
            "total_kills": 0,
            "best_time": 0,
            "prestige": 0,
            "prestige_points": 0,
            "boss_kills": 0,
            "evolved_weapons": 0,
            "selected_character": "hunter",
            "difficulty": "normal",
            "music_volume": 0.18,
            "sfx_volume": 0.8,
            "muted": False,
            "tutorial_seen": False,
            "unlocked_characters": ["hunter"],
            "unlocked_weapons": ["wand", "orbit", "knife", "spear", "boomerang"],
            "unlocked_relics": ["blood_crown", "moon_shard"],
            "permanent_upgrades": {key: 0 for key in PERMANENT_UPGRADES},
            "talents": {key: 0 for key in TALENTS},
            "achievements": [],
            "goal_rewards": [],
            "character_rewards": [],
            "ranking": [],
            "history": [],
            "codex_seen": {"enemies": [], "weapons": [], "relics": []},
        }

    def save_path(self):
        if 1 <= self.save_slot <= len(SAVE_SLOT_FILES):
            return SAVE_SLOT_FILES[self.save_slot - 1]
        return SAVE_FILE

    def load_progress(self):
        data = self.default_progress()
        try:
            path = self.save_path()
            if os.path.exists(path):
                with open(path, "r", encoding="utf-8") as file:
                    loaded = json.load(file)
                for key, value in loaded.items():
                    if isinstance(value, dict) and isinstance(data.get(key), dict):
                        data[key].update(value)
                    else:
                        data[key] = value
        except (OSError, json.JSONDecodeError):
            pass
        for key in ("wand", "orbit", "knife", "spear", "boomerang"):
            if key not in data["unlocked_weapons"]:
                data["unlocked_weapons"].append(key)
        return data

    def save_progress(self):
        try:
            with open(self.save_path(), "w", encoding="utf-8") as file:
                json.dump(self.progress, file, indent=2)
        except OSError:
            pass

    def switch_save_slot(self, slot):
        self.save_slot = clamp(slot, 1, len(SAVE_SLOT_FILES))
        self.progress = self.load_progress()
        self.selected_character = self.progress.get("selected_character", "hunter")
        self.difficulty = self.progress.get("difficulty", "normal")
        self.apply_audio_settings()
        self.reset()
        self.state = "menu"

    def nav_index(self, state=None):
        state = state or self.state
        return self.nav.get(state, 0)

    def set_nav_index(self, value, count, state=None):
        state = state or self.state
        if count <= 0:
            self.nav[state] = 0
        else:
            self.nav[state] = value % count

    def menu_count(self, state=None):
        state = state or self.state
        return {
            "menu": 10,
            "shop": len(PERMANENT_UPGRADES) + 1,
            "talents": len(TALENTS) + 1,
            "characters": len(CHARACTERS) + 1,
            "options": 4,
            "prestige": 2,
            "slots": len(SAVE_SLOT_FILES) + 1,
            "paused": 3,
            "tutorial": 1,
            "achievements": 1,
            "codex": 1,
            "records": 1,
        }.get(state, 0)

    def handle_navigation_key(self, key):
        state = self.state
        count = self.menu_count(state)
        idx = self.nav_index(state)
        if key == pygame.K_ESCAPE:
            if state in ("menu",):
                return
            if state == "paused":
                self.state = "playing"
            else:
                self.state = "menu"
            return
        if key in (pygame.K_UP, pygame.K_w):
            step = -3 if state == "characters" else -1
            self.set_nav_index(idx + step, count, state)
            self.play_sound("pickup", 0.12, 0.05)
            return
        if key in (pygame.K_DOWN, pygame.K_s):
            step = 3 if state == "characters" else 1
            self.set_nav_index(idx + step, count, state)
            self.play_sound("pickup", 0.12, 0.05)
            return
        if key in (pygame.K_LEFT, pygame.K_a):
            self.adjust_navigation_option(-1)
            return
        if key in (pygame.K_RIGHT, pygame.K_d):
            self.adjust_navigation_option(1)
            return
        if key in (pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_SPACE):
            self.activate_navigation_option()

    def adjust_navigation_option(self, direction):
        idx = self.nav_index()
        if self.state == "menu" and idx == 9:
            self.cycle_difficulty(direction)
        elif self.state == "options":
            if idx == 1:
                self.progress["music_volume"] = clamp(self.progress.get("music_volume", 0.18) + 0.04 * direction, 0, 1)
            elif idx == 2:
                self.progress["sfx_volume"] = clamp(self.progress.get("sfx_volume", 0.8) + 0.08 * direction, 0, 1)
            self.apply_audio_settings()
            self.save_progress()
        elif self.state == "characters":
            self.set_nav_index(idx + direction, self.menu_count(), self.state)
        elif self.state == "slots":
            self.set_nav_index(idx + direction, self.menu_count(), self.state)
        self.play_sound("pickup", 0.12, 0.05)

    def activate_navigation_option(self):
        idx = self.nav_index()
        if self.state == "menu":
            actions = ["start", "shop", "characters", "achievements", "talents", "prestige", "codex", "records", "slots", "difficulty"]
            action = actions[idx]
            if action == "start":
                if not self.progress.get("tutorial_seen", False):
                    self.state = "tutorial"
                else:
                    self.reset()
            elif action == "difficulty":
                self.cycle_difficulty()
            else:
                self.state = {
                    "shop": "shop",
                    "characters": "characters",
                    "achievements": "achievements",
                    "talents": "talents",
                    "prestige": "prestige",
                    "codex": "codex",
                    "records": "records",
                    "slots": "slots",
                }[action]
        elif self.state == "shop":
            if idx >= len(PERMANENT_UPGRADES):
                self.state = "menu"
            else:
                self.buy_permanent_upgrade(idx)
        elif self.state == "talents":
            if idx >= len(TALENTS):
                self.state = "menu"
            else:
                self.buy_talent(idx)
        elif self.state == "characters":
            if idx >= len(CHARACTERS):
                self.state = "menu"
            else:
                self.pick_character(idx)
        elif self.state == "options":
            if idx == 0:
                self.progress["muted"] = not self.progress.get("muted", False)
                self.apply_audio_settings()
                self.save_progress()
            elif idx == 3:
                self.state = "menu"
        elif self.state == "prestige":
            if idx == 0:
                self.do_prestige()
            else:
                self.state = "menu"
        elif self.state == "slots":
            if idx >= len(SAVE_SLOT_FILES):
                self.state = "menu"
            else:
                self.switch_save_slot(idx + 1)
        elif self.state == "paused":
            if idx == 0:
                self.state = "playing"
            elif idx == 1:
                self.reset()
            else:
                self.finalize_run(False)
                self.state = "menu"
        elif self.state == "tutorial":
            self.progress["tutorial_seen"] = True
            self.save_progress()
            self.state = "menu"
        elif self.state in ("achievements", "codex", "records"):
            self.state = "menu"
        self.play_sound("chest", 0.16, 0.08)

    def draw_nav_text(self, text, pos, index, color=TEXT, center=True, font=None):
        selected = self.nav_index() == index
        font = font or self.font
        draw_color = CYAN if selected else color
        if selected:
            marker_pos = (pos[0] - 210, pos[1]) if center else (pos[0] - 26, pos[1] + 13)
            pygame.draw.circle(self.screen, CYAN, marker_pos, 5)
        return draw_text(self.screen, font, text, pos, draw_color, center=center)

    def draw_panel(self, rect, fill=(18, 22, 32), border=(58, 67, 84), selected=False):
        pygame.draw.rect(self.screen, fill, rect, border_radius=8)
        pygame.draw.rect(self.screen, CYAN if selected else border, rect, 2 if selected else 1, border_radius=8)

    def draw_button(self, rect, text, index, color=TEXT, font=None, subtext=None):
        selected = self.nav_index() == index
        fill = (24, 31, 45) if selected else (20, 25, 36)
        border = CYAN if selected else (65, 74, 92)
        self.draw_panel(rect, fill, border, selected)
        if selected:
            pygame.draw.rect(self.screen, (33, 56, 78), (rect.x + 4, rect.y + 4, 5, rect.h - 8), border_radius=3)
        draw_text(self.screen, font or self.font, text, (rect.x + 18, rect.y + 9), CYAN if selected else color)
        if subtext:
            draw_text(self.screen, self.small_font, subtext, (rect.x + 18, rect.y + rect.h - 23), MUTED)

    def draw_bar(self, rect, value, max_value, color, label):
        pct = 0 if max_value <= 0 else clamp(value / max_value, 0, 1)
        pygame.draw.rect(self.screen, (12, 17, 25), rect, border_radius=5)
        fill = pygame.Rect(rect.x, rect.y, int(rect.w * pct), rect.h)
        pygame.draw.rect(self.screen, color, fill, border_radius=5)
        pygame.draw.rect(self.screen, (52, 61, 78), rect, 1, border_radius=5)
        draw_text(self.screen, self.small_font, label, (rect.x + 8, rect.y + rect.h / 2), TEXT, center=False)

    def draw_nav_rect(self, rect, index, color):
        selected = self.nav_index() == index
        self.draw_panel(rect, (24, 30, 43) if selected else (21, 26, 37), CYAN if selected else color, selected)

    def create_visual_assets(self):
        assets = {}

        def surface(size):
            return pygame.Surface((size, size), pygame.SRCALPHA).convert_alpha()

        def player_sprite(body, accent, hair=(64, 43, 28), weapon=(220, 235, 245)):
            img = surface(56)
            pygame.draw.ellipse(img, (16, 20, 28, 120), (14, 40, 28, 8))
            pygame.draw.line(img, (42, 32, 28), (18, 31), (12, 42), 4)
            pygame.draw.line(img, (42, 32, 28), (38, 31), (44, 42), 4)
            pygame.draw.line(img, body, (22, 35), (19, 47), 5)
            pygame.draw.line(img, body, (34, 35), (37, 47), 5)
            pygame.draw.polygon(img, body, [(18, 21), (38, 21), (42, 39), (14, 39)])
            pygame.draw.polygon(img, accent, [(22, 22), (34, 22), (31, 39), (25, 39)])
            pygame.draw.circle(img, (220, 168, 126), (28, 17), 10)
            pygame.draw.arc(img, hair, (17, 7, 22, 18), math.pi, math.tau, 5)
            pygame.draw.circle(img, (22, 25, 32), (24, 16), 2)
            pygame.draw.circle(img, (22, 25, 32), (32, 16), 2)
            pygame.draw.line(img, weapon, (38, 25), (49, 18), 3)
            pygame.draw.circle(img, (255, 255, 255, 90), (23, 12), 2)
            return img

        assets["player"] = player_sprite((78, 116, 198), (178, 220, 255))
        assets["player_hunter"] = player_sprite((78, 116, 198), (178, 220, 255))
        assets["player_knight"] = player_sprite((112, 122, 138), (224, 230, 238), (72, 58, 42))
        assets["player_mage"] = player_sprite((88, 74, 160), (124, 220, 255), (232, 232, 210), (160, 224, 255))
        assets["player_rogue"] = player_sprite((82, 88, 96), (255, 103, 166), (36, 30, 34))
        assets["player_alchemist"] = player_sprite((60, 124, 90), (248, 198, 83), (84, 54, 28))
        assets["player_monk"] = player_sprite((170, 114, 72), (255, 226, 150), (45, 34, 28), (230, 210, 170))

        def pixel_enemy(body, accent, kind="shade", size=64):
            px = pygame.Surface((32, 32), pygame.SRCALPHA).convert_alpha()
            outline = (18, 16, 14)
            shade = tuple(max(0, c - 44) for c in body)
            light = tuple(min(255, c + 48) for c in body)
            metal = (151, 131, 96)
            boot = (57, 38, 29)
            cloth = (94, 50, 38)

            def r(color, x, y, w, h):
                pygame.draw.rect(px, color, pygame.Rect(x, y, w, h))

            def outlined(color, x, y, w, h):
                r(outline, x - 1, y - 1, w + 2, h + 2)
                r(color, x, y, w, h)

            def eye(x, y):
                r((246, 221, 172), x, y, 2, 3)
                r(outline, x + 1, y, 1, 3)

            def chibi_base(face=(226, 162, 105), hair=(77, 45, 27), tunic=None):
                tunic = tunic or body
                r((0, 0, 0, 95), 10, 27, 13, 3)
                outlined(boot, 10, 23, 4, 5)
                outlined(boot, 18, 23, 4, 5)
                outlined(tunic, 9, 15, 14, 10)
                r(shade, 9, 21, 14, 4)
                outlined(face, 11, 8, 10, 9)
                r(hair, 9, 6, 14, 4)
                r(hair, 8, 9, 4, 5)
                r(hair, 20, 9, 3, 4)
                r(tuple(max(0, c - 24) for c in hair), 12, 5, 7, 2)
                eye(12, 12)
                eye(18, 12)

            if kind == "runner":
                chibi_base((168, 232, 174), (40, 96, 58), (57, 170, 90))
                r(accent, 8, 16, 4, 3)
                r(accent, 21, 16, 4, 3)
                r((222, 255, 214), 13, 6, 7, 2)
            elif kind == "brute":
                chibi_base((210, 145, 82), (92, 56, 28), (150, 97, 46))
                outlined(metal, 7, 14, 5, 8)
                outlined(metal, 21, 14, 5, 8)
                r(GOLD, 13, 18, 6, 2)
                r(outline, 11, 8, 3, 2)
                r(outline, 19, 8, 3, 2)
            elif kind == "archer":
                chibi_base((226, 162, 105), (68, 37, 28), (128, 70, 86))
                r((112, 56, 35), 7, 16, 3, 9)
                r((226, 196, 138), 6, 14, 1, 11)
                r((226, 196, 138), 5, 15, 1, 9)
                r(accent, 23, 16, 4, 2)
                r(PINK, 13, 17, 8, 2)
            elif kind == "exploder":
                chibi_base((210, 98, 61), (99, 42, 22), (150, 56, 34))
                outlined((77, 45, 31), 19, 16, 6, 7)
                r(ORANGE, 20, 17, 4, 4)
                r(GOLD, 21, 18, 2, 2)
                r(GOLD, 23, 14, 4, 2)
                r(ORANGE, 27, 12, 2, 2)
            elif kind == "summoner":
                chibi_base((197, 160, 232), (48, 29, 75), (88, 58, 146))
                r(VIOLET, 8, 7, 3, 4)
                r(VIOLET, 21, 7, 3, 4)
                r((226, 206, 255), 13, 17, 6, 6)
                r((40, 22, 62), 14, 18, 4, 4)
                r(accent, 15, 19, 2, 2)
            elif kind.startswith("boss"):
                face = (232, 118, 93) if kind == "boss" else ((184, 128, 232) if kind == "boss_warlock" else (140, 218, 242))
                robe = body
                chibi_base(face, (63, 35, 30), robe)
                r(outline, 8, 5, 16, 3)
                r(GOLD, 9, 3, 3, 4)
                r(GOLD, 15, 2, 3, 5)
                r(GOLD, 21, 3, 3, 4)
                r(accent, 8, 20, 16, 3)
                r(outline, 11, 12, 3, 2)
                r(outline, 19, 12, 3, 2)
                if kind == "boss_warlock":
                    r(VIOLET, 14, 17, 5, 5)
                    r((232, 210, 255), 15, 18, 3, 3)
                elif kind == "boss_frost":
                    r(CYAN, 13, 17, 7, 2)
                    r(CYAN, 15, 15, 3, 6)
            elif kind == "miniboss":
                chibi_base((225, 132, 82), (89, 48, 28), (133, 73, 45))
                outlined((125, 74, 40), 7, 14, 5, 10)
                outlined((125, 74, 40), 21, 14, 5, 10)
                r((242, 170, 82), 12, 7, 2, 2)
                r((242, 170, 82), 19, 7, 2, 2)
            else:
                chibi_base((224, 128, 112), (52, 30, 32), (136, 48, 64))
                r((84, 26, 40), 7, 17, 4, 7)
                r((84, 26, 40), 21, 17, 4, 7)
                r(accent, 12, 18, 8, 2)
                r(outline, 12, 13, 2, 2)
                r(outline, 18, 13, 2, 2)

            return pygame.transform.scale(px, (size, size))

        enemy_specs = {
            "shade": ((224, 74, 100), (255, 142, 162)),
            "runner": ((78, 205, 116), (180, 255, 190)),
            "brute": ((238, 174, 64), (255, 215, 104)),
            "archer": ((245, 95, 158), (255, 206, 230)),
            "exploder": ((214, 84, 45), (255, 184, 73)),
            "summoner": ((154, 105, 245), (210, 184, 255)),
            "boss": ((238, 62, 94), (255, 178, 190)),
            "boss_warlock": ((142, 84, 232), (224, 190, 255)),
            "boss_frost": ((86, 188, 226), (190, 238, 255)),
            "miniboss": ((235, 119, 72), (255, 184, 104)),
        }
        for key, (body, accent) in enemy_specs.items():
            assets[f"enemy_{key}"] = pixel_enemy(body, accent, key)

        gem = surface(28)
        pygame.draw.polygon(gem, (190, 235, 255), [(14, 3), (24, 12), (14, 25), (4, 12)])
        pygame.draw.polygon(gem, CYAN, [(14, 7), (20, 12), (14, 20), (8, 12)])
        assets["gem"] = gem

        chest = surface(40)
        pygame.draw.rect(chest, (90, 53, 18), (6, 16, 28, 16), border_radius=4)
        pygame.draw.rect(chest, GOLD, (6, 10, 28, 14), border_radius=4)
        pygame.draw.rect(chest, (255, 231, 136), (18, 10, 5, 22))
        pygame.draw.rect(chest, (55, 33, 18), (6, 21, 28, 4))
        assets["chest"] = chest

        def icon(draw_fn):
            img = surface(40)
            pygame.draw.rect(img, (19, 23, 32), (4, 4, 32, 32), border_radius=7)
            pygame.draw.rect(img, (66, 78, 98), (4, 4, 32, 32), 2, border_radius=7)
            draw_fn(img)
            return img

        assets["weapon_icon_wand"] = icon(lambda img: (pygame.draw.line(img, CYAN, (14, 28), (27, 11), 4), pygame.draw.circle(img, TEXT, (28, 10), 4)))
        assets["weapon_icon_orbit"] = icon(lambda img: (pygame.draw.circle(img, VIOLET, (20, 20), 11, 2), pygame.draw.circle(img, CYAN, (30, 20), 4), pygame.draw.circle(img, CYAN, (10, 20), 4)))
        assets["weapon_icon_knife"] = icon(lambda img: (pygame.draw.polygon(img, TEXT, [(13, 29), (27, 8), (31, 12), (17, 31)]), pygame.draw.line(img, (80, 50, 32), (11, 31), (18, 24), 4)))
        assets["weapon_icon_axe"] = icon(lambda img: (pygame.draw.line(img, (120, 78, 40), (20, 30), (20, 10), 4), pygame.draw.polygon(img, GOLD, [(19, 9), (31, 13), (23, 21), (19, 18)])))
        assets["weapon_icon_lightning"] = icon(lambda img: pygame.draw.polygon(img, CYAN, [(24, 7), (13, 22), (21, 22), (16, 33), (29, 16), (21, 16)]))
        assets["weapon_icon_bomb"] = icon(lambda img: (pygame.draw.circle(img, ORANGE, (20, 23), 10), pygame.draw.line(img, GOLD, (23, 14), (29, 8), 2)))
        assets["weapon_icon_drone"] = icon(lambda img: (pygame.draw.circle(img, GREEN, (20, 20), 8), pygame.draw.line(img, CYAN, (8, 20), (32, 20), 2), pygame.draw.line(img, CYAN, (20, 8), (20, 32), 2)))
        assets["weapon_icon_spear"] = icon(lambda img: (pygame.draw.line(img, TEXT, (12, 30), (27, 8), 3), pygame.draw.polygon(img, CYAN, [(26, 7), (31, 9), (27, 15)])))
        assets["weapon_icon_book"] = icon(lambda img: (pygame.draw.rect(img, PINK, (11, 10, 18, 22), border_radius=2), pygame.draw.line(img, TEXT, (20, 11), (20, 31), 1)))
        assets["weapon_icon_flame"] = icon(lambda img: (pygame.draw.polygon(img, ORANGE, [(20, 31), (12, 22), (19, 8), (28, 22)]), pygame.draw.polygon(img, GOLD, [(20, 29), (16, 22), (21, 14), (25, 23)])))
        assets["weapon_icon_scythe"] = icon(lambda img: (pygame.draw.arc(img, TEXT, (9, 7, 24, 24), -1.8, 1.5, 3), pygame.draw.line(img, (110, 72, 38), (14, 31), (26, 9), 3)))
        assets["weapon_icon_chain"] = icon(lambda img: (pygame.draw.circle(img, VIOLET, (15, 17), 6, 2), pygame.draw.circle(img, VIOLET, (25, 23), 6, 2), pygame.draw.line(img, TEXT, (18, 20), (22, 20), 2)))
        assets["weapon_icon_boomerang"] = icon(lambda img: (pygame.draw.arc(img, GOLD, (9, 9, 22, 22), -0.7, 3.7, 5), pygame.draw.circle(img, CYAN, (28, 15), 4), pygame.draw.circle(img, TEXT, (13, 27), 3)))
        assets["passive_icon_move"] = icon(lambda img: (pygame.draw.polygon(img, CYAN, [(12, 27), (19, 10), (25, 27)]), pygame.draw.line(img, TEXT, (10, 31), (29, 31), 2)))
        assets["passive_icon_regen"] = icon(lambda img: (pygame.draw.circle(img, GREEN, (20, 20), 11), pygame.draw.line(img, TEXT, (20, 13), (20, 27), 3), pygame.draw.line(img, TEXT, (13, 20), (27, 20), 3)))
        assets["passive_icon_magnet"] = icon(lambda img: (pygame.draw.arc(img, RED, (10, 10, 20, 22), 0, math.pi, 4), pygame.draw.rect(img, CYAN, (10, 20, 6, 8)), pygame.draw.rect(img, CYAN, (24, 20, 6, 8))))
        assets["passive_icon_armor"] = icon(lambda img: pygame.draw.polygon(img, (180, 196, 210), [(20, 8), (31, 13), (28, 28), (20, 33), (12, 28), (9, 13)]))
        assets["passive_icon_luck"] = icon(lambda img: (pygame.draw.circle(img, GOLD, (20, 20), 11), pygame.draw.circle(img, (80, 54, 18), (20, 20), 5)))
        assets["passive_icon_cooldown"] = icon(lambda img: (pygame.draw.circle(img, VIOLET, (20, 20), 12, 2), pygame.draw.line(img, TEXT, (20, 20), (20, 11), 2), pygame.draw.line(img, TEXT, (20, 20), (27, 23), 2)))
        assets["relic_icon_blood_crown"] = icon(lambda img: pygame.draw.polygon(img, RED, [(10, 28), (12, 14), (18, 23), (24, 14), (30, 28)]))
        assets["relic_icon_moon_shard"] = icon(lambda img: (pygame.draw.circle(img, CYAN, (21, 18), 11), pygame.draw.circle(img, (19, 23, 32), (26, 14), 10)))
        assets["relic_icon_phoenix_ember"] = assets["weapon_icon_flame"]
        assets["relic_icon_storm_ring"] = assets["passive_icon_cooldown"]
        assets["relic_icon_giant_belt"] = assets["passive_icon_armor"]

        for key, color in {
            "tree": (62, 112, 70),
            "stone": (112, 116, 132),
            "pillar": (126, 116, 99),
            "cactus": (76, 139, 88),
            "crate": (145, 92, 47),
        }.items():
            img = surface(56)
            if key == "tree":
                pygame.draw.ellipse(img, (20, 24, 18, 100), (11, 42, 34, 8))
                pygame.draw.rect(img, (88, 57, 34), (23, 27, 10, 22), border_radius=3)
                pygame.draw.line(img, (119, 74, 38), (28, 31), (18, 20), 3)
                pygame.draw.line(img, (119, 74, 38), (29, 31), (40, 19), 3)
                pygame.draw.circle(img, (39, 91, 55), (28, 20), 18)
                pygame.draw.circle(img, (54, 125, 66), (18, 25), 13)
                pygame.draw.circle(img, (70, 152, 77), (35, 26), 14)
                pygame.draw.circle(img, (98, 178, 88), (25, 14), 9)
                pygame.draw.circle(img, (27, 70, 47), (40, 18), 9)
            elif key == "cactus":
                pygame.draw.line(img, color, (28, 12), (28, 44), 8)
                pygame.draw.line(img, color, (28, 24), (17, 24), 6)
                pygame.draw.line(img, color, (17, 24), (17, 15), 6)
                pygame.draw.line(img, color, (29, 31), (40, 31), 6)
                pygame.draw.line(img, color, (40, 31), (40, 22), 6)
            elif key == "pillar":
                pygame.draw.rect(img, color, (17, 10, 22, 38), border_radius=3)
                pygame.draw.rect(img, (82, 76, 69), (13, 7, 30, 7), border_radius=2)
                pygame.draw.rect(img, (82, 76, 69), (13, 43, 30, 7), border_radius=2)
            elif key == "crate":
                pygame.draw.rect(img, (73, 45, 26), (11, 11, 34, 34), border_radius=3)
                pygame.draw.rect(img, color, (14, 14, 28, 28), border_radius=3)
                pygame.draw.line(img, (95, 58, 31), (15, 15), (41, 41), 3)
                pygame.draw.line(img, (95, 58, 31), (41, 15), (15, 41), 3)
            else:
                pygame.draw.circle(img, color, (28, 30), 18)
                pygame.draw.circle(img, (156, 160, 174), (21, 22), 5)
            assets[key] = img

        assets["tiles"] = self.create_tile_assets()

        return assets

    def load_external_assets(self, assets):
        def load_image(path):
            full_path = ASSET_DIR / path
            if not full_path.exists():
                return None
            try:
                return pygame.image.load(str(full_path)).convert_alpha()
            except pygame.error:
                return None

        tree = load_image("props/tree2-final.png")
        if tree:
            assets["tree"] = tree
        bush = load_image("props/qubodup-bush_0.png")
        if bush:
            assets["bush"] = bush
        berry_bush = load_image("props/qubodup-bush_berries_0.png")
        if berry_bush:
            assets["berry_bush"] = berry_bush
        mushrooms = load_image("props/littleshrooms.png")
        if mushrooms:
            assets["mushrooms"] = mushrooms

        grass_sheet = load_image("tiles/grass-tiles-2-small.png")
        if grass_sheet:
            tiles = assets["tiles"]
            names = [
                "grass",
                "grass_dark",
                "grass_flower",
                "grass_edge",
                "dirt",
                "dirt_rock",
                "grass_alt",
                "grass_clover",
                "grass_patch",
                "grass_corner",
                "dirt_alt",
                "dirt_path",
            ]
            for i, name in enumerate(names):
                x = (i % 6) * TILE_SIZE
                y = (i // 6) * TILE_SIZE
                tile = pygame.Surface((TILE_SIZE, TILE_SIZE), pygame.SRCALPHA).convert_alpha()
                tile.blit(grass_sheet, (0, 0), pygame.Rect(x, y, TILE_SIZE, TILE_SIZE))
                tiles[name] = tile

        def lpc_tile(sheet_name, col, row, base_color):
            sheet = load_image(f"tiles/lpc_terrain/twosided/{sheet_name}.png")
            if not sheet:
                return None
            tile = pygame.Surface((TILE_SIZE, TILE_SIZE), pygame.SRCALPHA).convert_alpha()
            tile.fill(base_color)
            tile.blit(sheet, (0, 0), pygame.Rect(col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE))
            return tile

        lpc_tiles = {
            "grass": ("grass", 2, 5, (50, 126, 55)),
            "grass_dark": ("grassalt", 1, 5, (43, 112, 53)),
            "grass_flower": ("tallgrass", 0, 5, (55, 132, 58)),
            "grass_clover": ("grass", 1, 5, (53, 132, 58)),
            "grass_patch": ("grassalt", 2, 5, (48, 120, 55)),
            "grave": ("dirt_night", 2, 5, (47, 52, 64)),
            "grave_path": ("dirt2", 2, 5, (78, 74, 70)),
            "ruin": ("cement", 2, 5, (92, 92, 88)),
            "ruin_crack": ("holemid", 2, 5, (80, 78, 72)),
            "sand": ("sand", 2, 5, (174, 140, 76)),
            "sand_dune": ("redsand", 2, 5, (174, 116, 64)),
            "border": ("watergrass", 1, 1, (36, 84, 112)),
            "border_path": ("dirt", 2, 5, (104, 82, 52)),
        }
        for name, (sheet_name, col, row, base_color) in lpc_tiles.items():
            tile = lpc_tile(sheet_name, col, row, base_color)
            if tile:
                assets["tiles"][name] = tile

        def load_dcss(path):
            return load_image(f"dcss/{path}")

        def assign_asset(key, path):
            image = load_dcss(path)
            if image:
                assets[key] = image

        dcss_tiles = {
            "grass": "dungeon/floor/grass/grass_0_new.png",
            "grass_dark": "dungeon/floor/grass/grass_1_new.png",
            "grass_flower": "dungeon/floor/grass/grass_flowers_yellow_1_new.png",
            "grass_clover": "dungeon/floor/grass/grass_flowers_red_1_new.png",
            "grass_patch": "dungeon/floor/grass/grass_2_new.png",
            "grass_edge": "dungeon/floor/grass/grass_0_new.png",
            "grave": "dungeon/floor/crypt_10.png",
            "grave_path": "dungeon/floor/grey_dirt_0_new.png",
            "ruin": "dungeon/floor/limestone_0.png",
            "ruin_crack": "dungeon/floor/mosaic_1.png",
            "sand": "dungeon/floor/floor_sand_stone_0.png",
            "sand_dune": "dungeon/floor/floor_sand_rock_0.png",
            "border": "dungeon/floor/cobble_blood_1_new.png",
            "border_path": "dungeon/floor/dirt_0_new.png",
        }
        for key, path in dcss_tiles.items():
            image = load_dcss(path)
            if image:
                assets["tiles"][key] = image

        for key, path in {
            "player": "player/base/human_male.png",
            "player_hunter": "player/base/human_male.png",
            "player_knight": "player/base/dwarf_male.png",
            "player_mage": "player/base/deep_elf_male.png",
            "player_rogue": "player/base/vampire_male.png",
            "player_alchemist": "player/base/orc_male.png",
            "player_monk": "player/base/human_male.png",
            "chest": "dungeon/chest_2_closed.png",
            "stone": "dungeon/boulder.png",
            "altar": "dungeon/altars/altar_base.png",
            "altar_heal": "dungeon/altars/altar_shining_one.png",
            "altar_storm": "dungeon/altars/altar_vehumet.png",
            "altar_gold": "dungeon/altars/altar_okawaru.png",
            "altar_elite": "dungeon/altars/altar_yredelemnul.png",
            "portal": "dungeon/gateways/enter_tartarus.png",
            "enemy_shade": "monster/undead/shadow_new.png",
            "enemy_runner": "monster/animals/bat.png",
            "enemy_brute": "monster/ogre_new.png",
            "enemy_archer": "monster/centaur_warrior.png",
            "enemy_exploder": "monster/demons/imp.png",
            "enemy_summoner": "monster/deep_elf_summoner.png",
            "enemy_boss": "monster/dragons/dragon.png",
            "enemy_boss_warlock": "monster/deep_elf_sorcerer.png",
            "enemy_boss_frost": "monster/undead/freezing_wraith.png",
            "enemy_miniboss": "monster/troll.png",
            "weapon_icon_wand": "item/wand/wand_silver.png",
            "weapon_icon_orbit": "item/misc/misc_orb.png",
            "weapon_icon_knife": "item/weapon/knife.png",
            "weapon_icon_axe": "item/weapon/hand_axe_1_new.png",
            "weapon_icon_lightning": "item/weapon/artefact/urand_storm_bow.png",
            "weapon_icon_bomb": "effect/cloud_fire_0.png",
            "weapon_icon_drone": "item/misc/misc_crystal_new.png",
            "weapon_icon_spear": "item/weapon/spear.png",
            "weapon_icon_book": "item/book/book_indigo.png",
            "weapon_icon_flame": "item/weapon/artefact/urand_firestarter.png",
            "weapon_icon_scythe": "item/weapon/scythe_1_new.png",
            "weapon_icon_chain": "item/weapon/bullwhip_new.png",
            "passive_icon_move": "item/weapon/quarterstaff_new.png",
            "passive_icon_regen": "item/potion/potion_sky_blue.png",
            "passive_icon_magnet": "item/misc/misc_crystal_new.png",
            "passive_icon_armor": "item/ring/gold_blue.png",
            "passive_icon_luck": "item/gold/gold_pile.png",
            "passive_icon_cooldown": "item/misc/misc_lamp_new.png",
            "relic_icon_blood_crown": "item/book/book_of_the_dead_new.png",
            "relic_icon_moon_shard": "item/misc/misc_orb.png",
            "relic_icon_phoenix_ember": "item/weapon/artefact/urand_firestarter.png",
            "relic_icon_storm_ring": "item/ring/gold_blue.png",
            "relic_icon_giant_belt": "item/amulet/eye_cyan.png",
            "projectile_enemy": "effect/magic_bolt_1.png",
            "projectile_wand": "effect/magic_dart_0.png",
            "projectile_knife": "effect/arrow_0.png",
            "projectile_lightning": "effect/zap_0.png",
            "projectile_flame": "effect/flame_0.png",
            "projectile_spear": "effect/crystal_spear_0.png",
            "player_body_hunter": "player/body/leather_armor.png",
            "player_body_knight": "player/body/plate_and_cloth.png",
            "player_body_mage": "player/body/robe_blue.png",
            "player_body_rogue": "player/body/leather_red.png",
            "player_body_alchemist": "player/body/robe_brown.png",
            "player_body_monk": "player/body/robe_white_green.png",
            "player_hair_hunter": "player/hair/aragorn.png",
        }.items():
            assign_asset(key, path)

        for character in CHARACTERS:
            base_key = f"player_{character}"
            body_key = f"player_body_{character}"
            if base_key in assets and body_key in assets:
                composed = pygame.Surface(assets[base_key].get_size(), pygame.SRCALPHA).convert_alpha()
                composed.blit(assets[base_key], (0, 0))
                composed.blit(assets[body_key], (0, 0))
                if character == "hunter" and "player_hair_hunter" in assets:
                    composed.blit(assets["player_hair_hunter"], (0, 0))
                assets[base_key] = composed

    def create_tile_assets(self):
        tiles = {}

        def tile(base, speckles, lines=None):
            surf = pygame.Surface((TILE_SIZE, TILE_SIZE), pygame.SRCALPHA).convert_alpha()
            surf.fill(base)
            for x, y, color in speckles:
                pygame.draw.rect(surf, color, (x, y, 2, 2))
            if lines:
                for color, start, end in lines:
                    pygame.draw.line(surf, color, start, end, 1)
            return surf

        tiles["grass"] = tile(
            (56, 134, 62),
            [(5, 7, (64, 146, 67)), (17, 11, (49, 124, 58)), (26, 22, (67, 150, 70)), (9, 26, (51, 128, 58))],
        )
        tiles["grass_dark"] = tile(
            (53, 128, 60),
            [(4, 19, (61, 142, 65)), (18, 5, (47, 118, 55)), (23, 24, (64, 145, 67))],
        )
        tiles["grass_flower"] = tile(
            (56, 134, 62),
            [(7, 12, (221, 207, 102)), (22, 19, (224, 132, 166)), (14, 26, (66, 150, 70))],
        )
        tiles["grave"] = tile(
            (48, 51, 68),
            [(6, 9, (67, 72, 91)), (18, 22, (38, 42, 58)), (26, 12, (78, 83, 101))],
        )
        tiles["grave_path"] = tile(
            (67, 69, 82),
            [(8, 8, (92, 96, 112)), (20, 16, (50, 54, 68)), (13, 27, (84, 87, 100))],
        )
        tiles["ruin"] = tile(
            (86, 73, 61),
            [(4, 4, (111, 95, 76)), (23, 9, (65, 55, 49)), (14, 24, (112, 95, 77))],
            [((71, 61, 53), (0, 0), (31, 0)), ((71, 61, 53), (0, 31), (31, 31)), ((71, 61, 53), (0, 0), (0, 31))],
        )
        tiles["ruin_crack"] = tile(
            (78, 67, 58),
            [(9, 20, (105, 88, 72)), (21, 7, (54, 48, 43))],
            [((46, 41, 38), (5, 7), (16, 17)), ((46, 41, 38), (16, 17), (26, 13))],
        )
        tiles["sand"] = tile(
            (154, 118, 62),
            [(6, 12, (185, 146, 79)), (19, 9, (124, 93, 50)), (25, 25, (177, 137, 73))],
        )
        tiles["sand_dune"] = tile(
            (166, 128, 67),
            [(12, 20, (190, 151, 82)), (24, 9, (132, 98, 52))],
            [((194, 152, 79), (3, 22), (28, 16)), ((128, 94, 49), (4, 25), (27, 19))],
        )
        tiles["border"] = tile((28, 32, 39), [(12, 12, (62, 69, 76)), (24, 22, (18, 22, 29))])
        tiles["border_path"] = tile((76, 84, 74), [(7, 7, (93, 103, 89)), (20, 18, (56, 64, 58))])
        return tiles

    def setup_audio(self):
        try:
            if not pygame.mixer.get_init():
                pygame.mixer.init(44100, -16, 1, 512)
            self.audio_enabled = True
            self.sounds = {
                "shoot": self.make_tone(760, 0.045, 0.18, "square"),
                "wand": self.make_tone(880, 0.05, 0.16, "sine"),
                "knife": self.make_tone(1180, 0.035, 0.13, "square"),
                "axe": self.make_tone(260, 0.09, 0.2, "saw"),
                "lightning": self.make_tone(1450, 0.08, 0.15, "noise"),
                "bomb": self.make_tone(95, 0.15, 0.24, "noise"),
                "drone": self.make_tone(620, 0.04, 0.12, "square"),
                "spear": self.make_tone(720, 0.055, 0.15, "saw"),
                "book": self.make_tone(520, 0.06, 0.12, "sine"),
                "flame": self.make_tone(180, 0.12, 0.18, "noise"),
                "scythe": self.make_tone(340, 0.12, 0.2, "saw"),
                "chain": self.make_tone(1320, 0.08, 0.16, "square"),
                "hit": self.make_tone(130, 0.06, 0.25, "noise"),
                "pickup": self.make_tone(980, 0.06, 0.16, "sine"),
                "level": self.make_chord((523, 659, 784), 0.35, 0.16),
                "chest": self.make_chord((392, 523, 659, 988), 0.45, 0.18),
                "hurt": self.make_tone(88, 0.16, 0.27, "saw"),
                "boom": self.make_tone(68, 0.22, 0.32, "noise"),
                "boss": self.make_chord((110, 82, 55), 0.7, 0.16),
                "evolve": self.make_chord((392, 587, 784, 1175), 0.8, 0.16),
                "legendary": self.make_chord((523, 784, 1046, 1568), 0.9, 0.2),
            }
            self.music_tracks = {
                "forest": self.make_music_loop((55, 65.4, 82.4, 98)),
                "graveyard": self.make_music_loop((49, 58.2, 73.4, 87.3)),
                "ruins": self.make_music_loop((61.7, 73.4, 92.5, 110)),
                "desert": self.make_music_loop((65.4, 77.8, 98, 116.5)),
                "boss": self.make_music_loop((41.2, 55, 61.7, 82.4)),
                "menu": self.make_music_loop((73.4, 82.4, 98, 123.5)),
            }
            self.current_music = "menu"
            self.music = self.music_tracks[self.current_music]
            self.music.set_volume(0.18)
            self.music.play(loops=-1)
        except pygame.error:
            self.audio_enabled = False

    def make_tone(self, freq, duration, volume, wave="sine"):
        sample_rate = 44100
        count = int(sample_rate * duration)
        data = array.array("h")
        for i in range(count):
            t = i / sample_rate
            fade = 1 - i / count
            if wave == "square":
                value = 1 if math.sin(math.tau * freq * t) > 0 else -1
            elif wave == "saw":
                value = 2 * ((freq * t) % 1) - 1
            elif wave == "noise":
                value = random.uniform(-1, 1) * fade
            else:
                value = math.sin(math.tau * freq * t)
            data.append(int(32767 * volume * value * fade))
        return pygame.mixer.Sound(buffer=data)

    def make_chord(self, freqs, duration, volume):
        sample_rate = 44100
        count = int(sample_rate * duration)
        data = array.array("h")
        for i in range(count):
            t = i / sample_rate
            fade = 1 - i / count
            value = sum(math.sin(math.tau * freq * t) for freq in freqs) / len(freqs)
            data.append(int(32767 * volume * value * fade))
        return pygame.mixer.Sound(buffer=data)

    def make_music_loop(self, notes=None):
        sample_rate = 44100
        duration = 4.0
        count = int(sample_rate * duration)
        base = list(notes or (55, 65.4, 73.4, 82.4))
        notes = base + base[::-1]
        data = array.array("h")
        for i in range(count):
            t = i / sample_rate
            beat = int(t * 2) % len(notes)
            bass = math.sin(math.tau * notes[beat] * t) * 0.55
            pulse = 1 if math.sin(math.tau * notes[beat] * 2 * t) > 0 else -1
            value = bass + pulse * 0.08
            data.append(int(32767 * 0.18 * value))
        return pygame.mixer.Sound(buffer=data)

    def set_music(self, key):
        if not self.audio_enabled or key == getattr(self, "current_music", None):
            return
        if key not in self.music_tracks:
            return
        try:
            self.music.stop()
            self.current_music = key
            self.music = self.music_tracks[key]
            self.apply_audio_settings()
            self.music.play(loops=-1)
        except pygame.error:
            pass

    def play_sound(self, key, volume=1.0, min_gap=0.04):
        if not self.audio_enabled or key not in self.sounds or self.progress.get("muted", False):
            return
        now = self.time_alive if hasattr(self, "time_alive") else 0
        if now - self.sound_cooldowns.get(key, -99) < min_gap:
            return
        self.sound_cooldowns[key] = now
        sound = self.sounds[key]
        sound.set_volume(volume * self.progress.get("sfx_volume", 0.8))
        sound.play()

    def apply_audio_settings(self):
        if self.audio_enabled and hasattr(self, "music"):
            volume = 0 if self.progress.get("muted", False) else self.progress.get("music_volume", 0.18)
            self.music.set_volume(volume)

    def reset(self):
        self.player = Player()
        self.run_xp_bonus = 0
        self.apply_run_progression()
        self.weapons = {"wand": Weapon("wand", 1, 0.76)}
        self.passives = {key: 0 for key in PASSIVE_INFO}
        self.enemies = []
        self.projectiles = []
        self.gems = []
        self.chests = []
        self.obstacles = []
        self.breakables = []
        self.terrain_details = []
        self.tile_map = []
        self.altars = []
        self.merchants = []
        self.portals = []
        self.pets = [Pet(self.player.x - 48, self.player.y + 24)]
        self.particles = []
        self.effects = []
        self.floating_text = []
        self.time_alive = 0
        self.goal_index = 0
        self.win_time = GOAL_OPTIONS[self.goal_index]
        self.spawn_timer = 0
        self.event_timer = 26
        self.event_name = ""
        self.event_time = 0
        self.pending_event = ""
        self.event_warning_time = 0
        self.event_objective = None
        self.next_boss_time = 120
        self.next_miniboss_time = 85
        self.relics = []
        self.relic_storm_timer = 0
        self.active_synergies = []
        self.map_modifier = random.choice(list(MAP_MODIFIERS))
        self.map_modifier_text = MAP_MODIFIERS[self.map_modifier][0]
        self.portal_timer = 0
        self.portal_kills = 0
        self.next_merchant_time = 95
        self.next_portal_time = 140
        self.next_story_time = 45
        self.story_text = ""
        self.story_time = 0
        self.replay_events = []
        self.state = "playing"
        self.upgrade_choices = []
        self.wave = 1
        self.score = 0
        self.kills = 0
        self.run_coins = 0
        self.run_boss_kills = 0
        self.run_evolved = 0
        self.run_finished_saved = False
        self.run_unlocked = []
        talents = self.progress.get("talents", {})
        self.rerolls = 2 + self.progress.get("permanent_upgrades", {}).get("rerolls", 0) // 3
        self.banishes = 1 + talents.get("planning", 0) // 2
        self.banned_upgrades = []
        self.damage_by_weapon = {key: 0 for key in WEAPON_INFO}
        self.damage_by_weapon["outros"] = 0
        self.shake = 0
        self.flash = 0
        self.infinite_mode = False
        self.joystick_origin = None
        self.joystick_pos = None
        self.render_cam = None
        self.mouse_aim_active = True
        self.nav = getattr(self, "nav", {})
        self.generate_map()

    def refresh_synergies(self):
        owned = set(self.weapons)
        active = []
        for key, (name, required, _desc) in SYNERGIES.items():
            if required.issubset(owned):
                active.append(key)
        if active == self.active_synergies:
            return
        newly_active = [key for key in active if key not in self.active_synergies]
        self.active_synergies = active
        for key in newly_active:
            self.run_unlocked.append(SYNERGIES[key][0])
            self.add_effect(self.player.x, self.player.y, "legendary", GOLD, 110, 0.7)
        self.apply_synergy_stats()

    def apply_synergy_stats(self):
        if "storm_mage" in self.active_synergies:
            self.player.damage_mult += 0.12
        if "pyromancer" in self.active_synergies:
            self.player.damage_mult += 0.18
        if "blade_dancer" in self.active_synergies:
            self.player.damage_mult += 0.10
            self.player.speed += 10
        if "orbit_master" in self.active_synergies:
            self.player.pickup_radius += 22

    def precise_pierce_bonus(self):
        return 1 if "ranger" in self.active_synergies else 0

    def apply_run_progression(self):
        upgrades = self.progress.get("permanent_upgrades", {})
        self.player.max_hp += upgrades.get("max_hp", 0) * 8
        self.player.hp = self.player.max_hp
        self.player.damage_mult += upgrades.get("damage", 0) * 0.04
        self.player.speed += upgrades.get("move", 0) * 6
        self.player.luck += upgrades.get("luck", 0) * 0.04
        self.player.armor += upgrades.get("armor", 0) * 0.4
        self.player.pickup_radius += upgrades.get("magnet", 0) * 10
        talents = self.progress.get("talents", {})
        prestige_bonus = 1 + self.progress.get("prestige", 0) * 0.03
        self.player.max_hp += talents.get("survival", 0) * 12
        self.player.regen += talents.get("survival", 0) * 0.08
        self.player.damage_mult += talents.get("weaponry", 0) * 0.06 * prestige_bonus
        self.player.pickup_radius += talents.get("collector", 0) * 18
        self.player.luck += talents.get("fortune", 0) * 0.08
        self.player.cooldown_mult *= max(0.65, 1 - talents.get("tempo", 0) * 0.03)
        self.run_xp_bonus = getattr(self, "run_xp_bonus", 0) + talents.get("growth", 0) * 0.04
        _name, _desc, stats = CHARACTERS.get(self.selected_character, CHARACTERS["hunter"])
        self.player.max_hp += stats.get("hp", 0)
        self.player.hp = self.player.max_hp
        self.player.speed += stats.get("speed", 0)
        self.player.damage_mult += stats.get("damage", 0)
        self.player.armor += stats.get("armor", 0)
        self.player.luck += stats.get("luck", 0)
        self.player.regen += stats.get("regen", 0)
        self.player.pickup_radius += stats.get("pickup", 0)

    def difficulty_mods(self):
        return DIFFICULTIES.get(self.difficulty, DIFFICULTIES["normal"])

    def generate_map(self):
        random.seed(42)
        self.obstacles = []
        self.breakables = []
        self.terrain_details = []
        self.altars = []
        x1, y1, x2, y2 = self.biome_bounds("forest")
        self.map_landmarks = [
            {"kind": "lake", "x": WORLD_W * 0.20, "y": WORLD_H * 0.55, "radius": 190},
            {"kind": "ruin", "x": WORLD_W * 0.68, "y": WORLD_H * 0.34, "radius": 145},
            {"kind": "boss_clearing", "x": WORLD_W * 0.82, "y": WORLD_H * 0.58, "radius": 165},
        ]
        self.map_clearings = [
            (self.player.x, self.player.y, 250),
            (WORLD_W * 0.50, WORLD_H * 0.50, 210),
            (WORLD_W * 0.24, WORLD_H * 0.25, 150),
            (WORLD_W * 0.76, WORLD_H * 0.24, 150),
            (WORLD_W * 0.25, WORLD_H * 0.76, 150),
            (WORLD_W * 0.76, WORLD_H * 0.76, 150),
            (WORLD_W * 0.68, WORLD_H * 0.34, 170),
            (WORLD_W * 0.82, WORLD_H * 0.58, 190),
        ]
        self.map_paths = [
            ((WORLD_W * 0.12, WORLD_H * 0.50), (WORLD_W * 0.88, WORLD_H * 0.50), 58),
            ((WORLD_W * 0.50, WORLD_H * 0.12), (WORLD_W * 0.50, WORLD_H * 0.88), 58),
            ((WORLD_W * 0.24, WORLD_H * 0.25), (WORLD_W * 0.50, WORLD_H * 0.50), 42),
            ((WORLD_W * 0.76, WORLD_H * 0.24), (WORLD_W * 0.50, WORLD_H * 0.50), 42),
            ((WORLD_W * 0.25, WORLD_H * 0.76), (WORLD_W * 0.50, WORLD_H * 0.50), 42),
            ((WORLD_W * 0.76, WORLD_H * 0.76), (WORLD_W * 0.50, WORLD_H * 0.50), 42),
            ((WORLD_W * 0.50, WORLD_H * 0.50), (WORLD_W * 0.68, WORLD_H * 0.34), 46),
            ((WORLD_W * 0.50, WORLD_H * 0.50), (WORLD_W * 0.82, WORLD_H * 0.58), 52),
            ((WORLD_W * 0.20, WORLD_H * 0.55), (WORLD_W * 0.50, WORLD_H * 0.50), 38),
        ]
        for _ in range(520):
            x = random.uniform(x1 + 20, x2 - 20)
            y = random.uniform(y1 + 20, y2 - 20)
            zone = self.map_zone_at(x, y)
            if zone in ("clearing", "ruin", "boss_clearing", "lake") and random.random() < 0.62:
                continue
            detail_kind = random.choice(("grass", "grass", "grass", "flower", "leaf"))
            if zone == "path":
                detail_color = random.choice(((83, 150, 78), (97, 166, 84), (186, 174, 92)))
                detail_kind = random.choice(("grass", "leaf", "pebble"))
            elif zone == "ruin":
                detail_color = random.choice(((95, 105, 92), (119, 126, 108), (74, 86, 72)))
                detail_kind = random.choice(("pebble", "crack", "tile", "grass"))
            elif zone == "lake":
                detail_color = random.choice(((78, 158, 124), (100, 176, 132), (126, 190, 142)))
                detail_kind = random.choice(("grass", "leaf", "pebble"))
            elif zone == "boss_clearing":
                detail_color = random.choice(((98, 87, 78), (136, 112, 72), (90, 135, 74)))
                detail_kind = random.choice(("pebble", "crack", "grass", "rune"))
            else:
                detail_color = random.choice(((66, 150, 72), (84, 176, 82), (112, 196, 93), (231, 207, 100), (235, 128, 166)))
            self.terrain_details.append(TerrainDetail(x, y, detail_kind, detail_color, random.randint(3, 8)))
        self.add_landmark_details()
        for _ in range(126):
            x = random.uniform(x1 + 70, x2 - 70)
            y = random.uniform(y1 + 70, y2 - 70)
            zone = self.map_zone_at(x, y)
            near_tree = any(length(x - o.x, y - o.y) < o.radius + 46 for o in self.obstacles)
            if zone == "wild" and not near_tree and length(x - self.player.x, y - self.player.y) > 260:
                self.obstacles.append(Obstacle(x, y, random.randint(16, 32), "tree", (62, 95, 68)))
        altar_specs = [
            (WORLD_W * 0.24, WORLD_H * 0.25, "heal"),
            (WORLD_W * 0.76, WORLD_H * 0.24, "storm"),
            (WORLD_W * 0.25, WORLD_H * 0.76, "gold"),
            (WORLD_W * 0.76, WORLD_H * 0.76, "elite"),
            (WORLD_W * 0.50, WORLD_H * 0.50, "xp"),
        ]
        self.altars = [Altar(x, y, 24, kind) for x, y, kind in altar_specs]
        self.merchants = [Merchant(WORLD_W * 0.5 + 110, WORLD_H * 0.5 - 85)]
        self.generate_tile_map()
        random.seed()

    def add_landmark_details(self):
        for landmark in self.map_landmarks:
            x, y, radius = landmark["x"], landmark["y"], landmark["radius"]
            if landmark["kind"] == "ruin":
                for ox, oy, size in ((-64, -38, 18), (-24, -70, 14), (36, -44, 20), (72, 18, 16), (-58, 44, 13), (14, 58, 15)):
                    self.terrain_details.append(TerrainDetail(x + ox, y + oy, "tile", (118, 125, 110), size))
                for ox, oy in ((-88, -4), (-36, 22), (44, 44), (86, -22)):
                    self.terrain_details.append(TerrainDetail(x + ox, y + oy, "crack", (74, 83, 70), 14))
            elif landmark["kind"] == "lake":
                for i in range(20):
                    angle = math.tau * i / 20
                    wobble = 0.72 + (i % 4) * 0.07
                    self.terrain_details.append(TerrainDetail(x + math.cos(angle) * radius * wobble, y + math.sin(angle) * radius * 0.48 * wobble, "grass", (88, 170, 106), random.randint(6, 10)))
            elif landmark["kind"] == "boss_clearing":
                for i in range(12):
                    angle = math.tau * i / 12
                    self.terrain_details.append(TerrainDetail(x + math.cos(angle) * 92, y + math.sin(angle) * 92, "rune", (178, 132, 72), 8))

    def distance_to_segment(self, px, py, start, end):
        ax, ay = start
        bx, by = end
        vx, vy = bx - ax, by - ay
        wx, wy = px - ax, py - ay
        seg_len = vx * vx + vy * vy
        if seg_len <= 0:
            return length(px - ax, py - ay)
        t = clamp((wx * vx + wy * vy) / seg_len, 0, 1)
        return length(px - (ax + vx * t), py - (ay + vy * t))

    def map_zone_at(self, x, y):
        for landmark in getattr(self, "map_landmarks", []):
            lx, ly, radius = landmark["x"], landmark["y"], landmark["radius"]
            dist = length(x - lx, y - ly)
            if landmark["kind"] == "lake":
                if ((x - lx) / radius) ** 2 + ((y - ly) / (radius * 0.55)) ** 2 <= 1:
                    return "lake"
            elif dist <= radius:
                return landmark["kind"]
        for cx, cy, radius in getattr(self, "map_clearings", []):
            if length(x - cx, y - cy) <= radius:
                return "clearing"
        for start, end, width in getattr(self, "map_paths", []):
            if self.distance_to_segment(x, y, start, end) <= width:
                return "path"
        return "wild"

    def generate_tile_map(self):
        self.tile_map = []
        for row in range(MAP_ROWS):
            tiles_row = []
            for col in range(MAP_COLS):
                x = col * TILE_SIZE + TILE_SIZE / 2
                y = row * TILE_SIZE + TILE_SIZE / 2
                zone = self.map_zone_at(x, y)
                noise = (col * 17 + row * 31 + (col // 3) * 7 + (row // 4) * 11) % 100
                if zone == "lake":
                    tile_id = "grass_dark" if noise < 70 else "grass"
                elif zone == "ruin":
                    tile_id = "grass_dark" if noise < 62 else "grass"
                elif zone == "boss_clearing":
                    tile_id = "grass_dark" if noise < 44 else ("grass_flower" if noise > 94 else "grass")
                elif zone == "path":
                    tile_id = "grass_dark" if noise < 54 else "grass"
                elif zone == "clearing":
                    tile_id = "grass_dark" if noise < 18 else ("grass_flower" if noise > 91 else "grass")
                elif noise < 10:
                    tile_id = "grass_flower"
                elif noise < 34:
                    tile_id = "grass_dark"
                else:
                    tile_id = "grass"
                tiles_row.append(tile_id)
            self.tile_map.append(tiles_row)

    def draw_tilemap(self, cam_x, cam_y):
        start_col = max(0, int(cam_x // TILE_SIZE) - 1)
        end_col = min(MAP_COLS, int((cam_x + WIDTH) // TILE_SIZE) + 2)
        start_row = max(0, int(cam_y // TILE_SIZE) - 1)
        end_row = min(MAP_ROWS, int((cam_y + HEIGHT) // TILE_SIZE) + 2)
        tiles = self.assets["tiles"]
        for row in range(start_row, end_row):
            for col in range(start_col, end_col):
                tile_id = self.tile_map[row][col]
                self.screen.blit(tiles[tile_id], (col * TILE_SIZE - cam_x, row * TILE_SIZE - cam_y))

    def biome_bounds(self, biome):
        return 0, 0, WORLD_W, WORLD_H

    def biome_at(self, x, y):
        return "forest"

    def draw_terrain_detail(self, detail):
        pos = self.screen_pos(detail.x, detail.y)
        if not (-30 < pos[0] < WIDTH + 30 and -30 < pos[1] < HEIGHT + 30):
            return
        if detail.kind == "grass":
            for i in range(3):
                offset = (i - 1) * detail.size * 0.35
                pygame.draw.line(self.screen, detail.color, (pos[0] + offset, pos[1] + detail.size), (pos[0] + offset * 0.35, pos[1] - detail.size), 2)
        elif detail.kind in ("bush", "berry_bush", "mushrooms") and detail.kind in self.assets:
            size = 24 if detail.kind == "mushrooms" else 28
            self.blit_asset(detail.kind, pos[0], pos[1], size)
        elif detail.kind == "flower":
            pygame.draw.circle(self.screen, detail.color, pos, max(2, detail.size // 2))
            pygame.draw.circle(self.screen, (246, 230, 130), pos, 2)
        elif detail.kind == "leaf":
            pygame.draw.ellipse(self.screen, detail.color, (pos[0] - detail.size, pos[1] - detail.size / 2, detail.size * 2, detail.size))
        elif detail.kind == "grave":
            pygame.draw.rect(self.screen, detail.color, (pos[0] - detail.size / 2, pos[1] - detail.size, detail.size, detail.size * 1.4), border_radius=3)
        elif detail.kind == "mist":
            pygame.draw.circle(self.screen, (*detail.color,), pos, max(2, detail.size // 2), 1)
        elif detail.kind == "pebble":
            pygame.draw.circle(self.screen, detail.color, pos, max(2, detail.size // 3))
        elif detail.kind == "crack":
            pygame.draw.line(self.screen, detail.color, (pos[0] - detail.size, pos[1]), (pos[0] - detail.size * 0.2, pos[1] + detail.size * 0.3), 2)
            pygame.draw.line(self.screen, detail.color, (pos[0] - detail.size * 0.2, pos[1] + detail.size * 0.3), (pos[0] + detail.size, pos[1] - detail.size * 0.2), 2)
        elif detail.kind == "tile":
            pygame.draw.rect(self.screen, detail.color, (pos[0] - detail.size, pos[1] - detail.size, detail.size * 2, detail.size * 2), 1)
        elif detail.kind == "rune":
            pygame.draw.circle(self.screen, detail.color, pos, detail.size, 1)
            pygame.draw.line(self.screen, detail.color, (pos[0] - detail.size, pos[1]), (pos[0] + detail.size, pos[1]), 1)
        elif detail.kind == "dune":
            pygame.draw.arc(self.screen, detail.color, (pos[0] - detail.size, pos[1] - detail.size / 2, detail.size * 2, detail.size), 0, math.pi, 2)
        elif detail.kind == "dry_bush":
            pygame.draw.line(self.screen, detail.color, (pos[0], pos[1] + detail.size), (pos[0], pos[1] - detail.size), 2)
            pygame.draw.line(self.screen, detail.color, (pos[0], pos[1]), (pos[0] - detail.size, pos[1] - detail.size * 0.6), 2)
            pygame.draw.line(self.screen, detail.color, (pos[0], pos[1]), (pos[0] + detail.size, pos[1] - detail.size * 0.6), 2)
        elif detail.kind == "bone":
            pygame.draw.line(self.screen, detail.color, (pos[0] - detail.size, pos[1]), (pos[0] + detail.size, pos[1]), 3)
            pygame.draw.circle(self.screen, detail.color, (pos[0] - detail.size, pos[1]), 3)
            pygame.draw.circle(self.screen, detail.color, (pos[0] + detail.size, pos[1]), 3)

    def camera(self):
        return (
            clamp(self.player.x - WIDTH / 2, 0, WORLD_W - WIDTH),
            clamp(self.player.y - HEIGHT / 2, 0, WORLD_H - HEIGHT),
        )

    def screen_pos(self, x, y):
        cam_x, cam_y = self.render_cam if self.render_cam else self.camera()
        return x - cam_x, y - cam_y

    def draw_map_landmarks(self):
        for landmark in getattr(self, "map_landmarks", []):
            x, y, radius = landmark["x"], landmark["y"], landmark["radius"]
            pos = self.screen_pos(x, y)
            if not (-radius < pos[0] < WIDTH + radius and -radius < pos[1] < HEIGHT + radius):
                continue
            if landmark["kind"] == "lake":
                surf = pygame.Surface((int(radius * 2.15), int(radius * 1.25)), pygame.SRCALPHA)
                center = (surf.get_width() // 2, surf.get_height() // 2)
                pygame.draw.ellipse(surf, (35, 96, 112, 180), (8, 12, surf.get_width() - 16, surf.get_height() - 24))
                pygame.draw.ellipse(surf, (60, 147, 154, 120), (24, 24, surf.get_width() - 48, surf.get_height() - 48))
                pygame.draw.ellipse(surf, (120, 210, 188, 85), (54, 38, surf.get_width() - 108, surf.get_height() - 76), 3)
                for i in range(7):
                    yy = center[1] - 24 + i * 8
                    pygame.draw.arc(surf, (170, 235, 215, 70), (44 + i * 6, yy, surf.get_width() - 88 - i * 12, 20), 0, math.pi, 1)
                self.screen.blit(surf, (pos[0] - center[0], pos[1] - center[1]))
            elif landmark["kind"] == "ruin":
                color = (105, 112, 98)
                shadow = (30, 34, 30)
                blocks = [(-72, -44, 34, 66), (-28, -68, 28, 54), (18, -52, 56, 26), (48, -14, 36, 70), (-62, 36, 92, 24)]
                for bx, by, bw, bh in blocks:
                    rect = pygame.Rect(pos[0] + bx, pos[1] + by, bw, bh)
                    pygame.draw.rect(self.screen, shadow, rect.move(4, 5), border_radius=3)
                    pygame.draw.rect(self.screen, color, rect, border_radius=3)
                    pygame.draw.rect(self.screen, (63, 72, 62), rect, 2, border_radius=3)
                pygame.draw.circle(self.screen, (126, 170, 118), pos, 72, 2)
            elif landmark["kind"] == "boss_clearing":
                pulse = 1 + math.sin(self.time_alive * 2.2) * 0.04
                pygame.draw.circle(self.screen, (72, 52, 42), pos, int(radius * 0.74), 3)
                pygame.draw.circle(self.screen, (178, 126, 72), pos, int(82 * pulse), 2)
                for i in range(10):
                    angle = math.tau * i / 10 + self.time_alive * 0.25
                    inner = (pos[0] + math.cos(angle) * 42, pos[1] + math.sin(angle) * 42)
                    outer = (pos[0] + math.cos(angle) * 82, pos[1] + math.sin(angle) * 82)
                    pygame.draw.line(self.screen, (136, 98, 68), inner, outer, 2)

    def resolve_circle(self, x, y, radius):
        for landmark in getattr(self, "map_landmarks", []):
            if landmark["kind"] != "lake":
                continue
            lx, ly = landmark["x"], landmark["y"]
            rx = landmark["radius"] + radius
            ry = landmark["radius"] * 0.55 + radius
            nx = (x - lx) / rx
            ny = (y - ly) / ry
            if nx * nx + ny * ny < 1:
                angle = math.atan2(ny, nx)
                if nx == 0 and ny == 0:
                    angle = 0
                x = lx + math.cos(angle) * rx
                y = ly + math.sin(angle) * ry
        for obstacle in self.obstacles:
            dx = x - obstacle.x
            dy = y - obstacle.y
            dist = length(dx, dy)
            min_dist = radius + obstacle.radius
            if 0 < dist < min_dist:
                nx, ny = dx / dist, dy / dist
                x = obstacle.x + nx * min_dist
                y = obstacle.y + ny * min_dist
            elif dist == 0:
                x += min_dist
        for item in self.breakables:
            dx = x - item.x
            dy = y - item.y
            dist = length(dx, dy)
            min_dist = radius + item.radius
            if 0 < dist < min_dist:
                nx, ny = dx / dist, dy / dist
                x = item.x + nx * min_dist
                y = item.y + ny * min_dist
        return clamp(x, radius, WORLD_W - radius), clamp(y, radius, WORLD_H - radius)

    def damage_breakable(self, item, damage):
        item.hp -= damage
        self.hit_burst(item.x, item.y, item.color)
        if item.hp <= 0 and item in self.breakables:
            self.breakables.remove(item)
            reward = random.choice(("gem", "gem", "heal", "gold"))
            if reward == "heal":
                self.player.hp = min(self.player.max_hp, self.player.hp + 12)
                self.floating_text.append([item.x, item.y - 20, "+vida", 0.9, GREEN])
            else:
                value = 8 if reward == "gold" else 5
                self.gems.append(Gem(item.x, item.y, value, 7))
            for _ in range(10):
                self.particles.append(Particle(item.x, item.y, random.uniform(-120, 120), random.uniform(-120, 120), 0.28, item.color, random.uniform(2, 4)))

    def spawn_position(self, margin=90):
        cam_x, cam_y = self.camera()
        for _ in range(16):
            side = random.choice(("top", "bottom", "left", "right"))
            if side == "top":
                x = random.uniform(cam_x - margin, cam_x + WIDTH + margin)
                y = cam_y - margin
            elif side == "bottom":
                x = random.uniform(cam_x - margin, cam_x + WIDTH + margin)
                y = cam_y + HEIGHT + margin
            elif side == "left":
                x = cam_x - margin
                y = random.uniform(cam_y - margin, cam_y + HEIGHT + margin)
            else:
                x = cam_x + WIDTH + margin
                y = random.uniform(cam_y - margin, cam_y + HEIGHT + margin)
            x, y = clamp(x, 24, WORLD_W - 24), clamp(y, 24, WORLD_H - 24)
            if self.map_zone_at(x, y) != "lake" and not any(length(x - o.x, y - o.y) < o.radius + 34 for o in self.obstacles):
                return x, y
        return clamp(x, 24, WORLD_W - 24), clamp(y, 24, WORLD_H - 24)

    def spawn_enemy(self, kind=None, elite=False):
        x, y = self.spawn_position()
        _label, hp_mod, speed_mod, _coin_mod = self.difficulty_mods()
        minute_scale = 1 + self.time_alive / 120
        if self.map_modifier == "blood_moon":
            minute_scale *= 1.12
        if self.infinite_mode:
            minute_scale += (self.time_alive - self.win_time) / 160

        if kind is None:
            roll = random.random()
            if self.time_alive < 20:
                kind = "shade" if roll < 0.72 else "runner"
            elif self.time_alive < 55:
                if roll < 0.10:
                    kind = "brute"
                elif roll < 0.28:
                    kind = "runner"
                else:
                    kind = "shade"
            elif roll < min(0.08 + self.time_alive / 500, 0.22):
                kind = "archer"
            elif roll < min(0.16 + self.time_alive / 650, 0.28):
                kind = "exploder"
            elif roll < min(0.24 + self.time_alive / 600, 0.36):
                kind = "summoner"
            elif roll < min(0.40 + self.time_alive / 600, 0.54):
                kind = "brute"
            elif roll < 0.62:
                kind = "runner"
            else:
                kind = "shade"
        self.mark_codex("enemies", kind)

        stats = {
            "shade": (16, 30, 92, 10, 4),
            "runner": (12, 22, 150, 8, 3),
            "brute": (26, 82, 66, 17, 7),
            "archer": (15, 34, 78, 12, 6),
            "exploder": (18, 42, 122, 24, 7),
            "summoner": (21, 62, 64, 12, 8),
            "boss": (46, 650, 58, 28, 60),
            "miniboss": (34, 260, 78, 22, 28),
        }[kind]
        radius, hp, speed, damage, xp = stats
        if elite:
            radius += 7
            hp *= 2.7
            damage *= 1.5
            xp *= 3
        if self.map_modifier == "gold_rush":
            speed *= 1.12
        if self.map_modifier == "glass_night":
            hp *= 0.82
            damage *= 1.28
        if self.map_modifier == "blood_moon" and random.random() < 0.08:
            elite = True
        self.enemies.append(Enemy(x, y, radius, hp * minute_scale * hp_mod, speed * speed_mod, damage * hp_mod, xp, kind, elite))

    def spawn_boss(self):
        x, y = self.spawn_position(130)
        _label, hp_mod, speed_mod, _coin_mod = self.difficulty_mods()
        variants = ("boss", "boss_warlock", "boss_frost")
        kind = variants[(self.run_boss_kills + self.wave) % len(variants)]
        self.mark_codex("enemies", kind)
        hp = (650 + self.wave * 90) * hp_mod
        if self.infinite_mode:
            hp *= 1.7
        self.enemies.append(Enemy(x, y, 48, hp, 54 * speed_mod, 30 * hp_mod, 80, kind, True))
        self.event_name = "Chefe chegou"
        self.event_time = 4
        self.play_sound("boss", 0.4, 0.5)

    def spawn_miniboss(self):
        x, y = self.spawn_position(120)
        _label, hp_mod, speed_mod, _coin_mod = self.difficulty_mods()
        self.enemies.append(Enemy(x, y, 34, (240 + self.wave * 42) * hp_mod, 80 * speed_mod, 20 * hp_mod, 30, "miniboss", True))
        self.mark_codex("enemies", "miniboss")
        self.event_name = "Mini-chefe"
        self.event_time = 3

    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            if event.type == pygame.WINDOWFOCUSLOST and self.state == "playing":
                self.state = "paused"
            if event.type == pygame.KEYDOWN:
                if self.state in ("menu", "shop", "characters", "achievements", "options", "tutorial", "talents", "prestige", "codex", "records", "slots", "paused"):
                    self.handle_navigation_key(event.key)
                    continue
                if self.state == "menu":
                    if event.key in (pygame.K_RETURN, pygame.K_SPACE):
                        if not self.progress.get("tutorial_seen", False):
                            self.state = "tutorial"
                        else:
                            self.reset()
                    elif event.key == pygame.K_s:
                        self.state = "shop"
                    elif event.key == pygame.K_c:
                        self.state = "characters"
                    elif event.key == pygame.K_a:
                        self.state = "achievements"
                    elif event.key == pygame.K_t:
                        self.state = "talents"
                    elif event.key == pygame.K_x:
                        self.state = "prestige"
                    elif event.key == pygame.K_k:
                        self.state = "codex"
                    elif event.key == pygame.K_l:
                        self.state = "records"
                    elif event.key == pygame.K_v:
                        self.state = "slots"
                    elif event.key == pygame.K_o:
                        self.state = "options"
                    elif event.key == pygame.K_h:
                        self.state = "tutorial"
                    elif event.key == pygame.K_d:
                        self.cycle_difficulty()
                    continue
                if self.state == "talents":
                    if event.key == pygame.K_ESCAPE:
                        self.state = "menu"
                    elif pygame.K_1 <= event.key <= pygame.K_5:
                        self.buy_talent(event.key - pygame.K_1)
                    continue
                if self.state == "prestige":
                    if event.key == pygame.K_ESCAPE:
                        self.state = "menu"
                    elif event.key == pygame.K_RETURN:
                        self.do_prestige()
                    continue
                if self.state == "codex":
                    if event.key == pygame.K_ESCAPE:
                        self.state = "menu"
                    continue
                if self.state == "records":
                    if event.key == pygame.K_ESCAPE:
                        self.state = "menu"
                    continue
                if self.state == "slots":
                    if event.key == pygame.K_ESCAPE:
                        self.state = "menu"
                    elif event.key in (pygame.K_1, pygame.K_2, pygame.K_3):
                        self.switch_save_slot(event.key - pygame.K_0)
                    continue
                if self.state == "tutorial":
                    if event.key in (pygame.K_ESCAPE, pygame.K_RETURN, pygame.K_SPACE):
                        self.progress["tutorial_seen"] = True
                        self.save_progress()
                        self.state = "menu"
                    continue
                if self.state == "options":
                    if event.key == pygame.K_ESCAPE:
                        self.state = "menu"
                    elif event.key == pygame.K_m:
                        self.progress["muted"] = not self.progress.get("muted", False)
                    elif event.key == pygame.K_LEFT:
                        self.progress["music_volume"] = clamp(self.progress.get("music_volume", 0.18) - 0.04, 0, 1)
                    elif event.key == pygame.K_RIGHT:
                        self.progress["music_volume"] = clamp(self.progress.get("music_volume", 0.18) + 0.04, 0, 1)
                    elif event.key == pygame.K_DOWN:
                        self.progress["sfx_volume"] = clamp(self.progress.get("sfx_volume", 0.8) - 0.08, 0, 1)
                    elif event.key == pygame.K_UP:
                        self.progress["sfx_volume"] = clamp(self.progress.get("sfx_volume", 0.8) + 0.08, 0, 1)
                    self.apply_audio_settings()
                    self.save_progress()
                    continue
                if self.state == "shop":
                    if event.key == pygame.K_ESCAPE:
                        self.state = "menu"
                    elif event.key in (pygame.K_1, pygame.K_2, pygame.K_3, pygame.K_4, pygame.K_5):
                        self.buy_permanent_upgrade(event.key - pygame.K_1)
                    continue
                if self.state == "characters":
                    if event.key == pygame.K_ESCAPE:
                        self.state = "menu"
                    elif pygame.K_1 <= event.key <= pygame.K_6:
                        self.pick_character(event.key - pygame.K_1)
                    continue
                if self.state == "achievements":
                    if event.key == pygame.K_ESCAPE:
                        self.state = "menu"
                    continue
                if self.state == "paused":
                    if event.key in (pygame.K_p, pygame.K_ESCAPE):
                        self.state = "playing"
                    elif event.key == pygame.K_r:
                        self.reset()
                    elif event.key == pygame.K_m:
                        self.finalize_run(False)
                        self.state = "menu"
                    continue
                if self.state == "playing" and event.key == pygame.K_p:
                    self.state = "paused"
                    continue
                if event.key == pygame.K_r and self.state in ("game_over", "victory"):
                    self.reset()
                if event.key == pygame.K_m and self.state in ("game_over", "victory"):
                    self.state = "menu"
                if event.key == pygame.K_i and self.state == "victory":
                    self.infinite_mode = True
                    self.state = "playing"
                    self.event_name = "Modo infinito"
                    self.event_time = 4
                if event.key in (pygame.K_F1, pygame.K_F2, pygame.K_F3) and self.time_alive < 5:
                    self.goal_index = (pygame.K_F1, pygame.K_F2, pygame.K_F3).index(event.key)
                    self.win_time = GOAL_OPTIONS[self.goal_index]
                    self.event_name = f"Meta: {self.win_time // 60} minutos"
                    self.event_time = 3
                if event.key == pygame.K_ESCAPE and self.state in ("upgrade", "chest"):
                    self.pick_upgrade(0)
                if self.state in ("upgrade", "chest"):
                    if event.key == pygame.K_r:
                        self.reroll_upgrades()
                    elif event.key == pygame.K_b:
                        self.banish_upgrade(0)
                    if event.key in (pygame.K_1, pygame.K_KP1):
                        self.pick_upgrade(0)
                    elif event.key in (pygame.K_2, pygame.K_KP2):
                        self.pick_upgrade(1)
                    elif event.key in (pygame.K_3, pygame.K_KP3):
                        self.pick_upgrade(2)
            if event.type == pygame.MOUSEBUTTONDOWN and self.state in ("upgrade", "chest"):
                self.click_upgrade(event.pos)
            if event.type == pygame.FINGERDOWN:
                self.joystick_origin = (event.x * WIDTH, event.y * HEIGHT)
                self.joystick_pos = self.joystick_origin
            if event.type == pygame.FINGERMOTION and self.joystick_origin:
                self.joystick_pos = (event.x * WIDTH, event.y * HEIGHT)
            if event.type == pygame.FINGERUP:
                self.joystick_origin = None
                self.joystick_pos = None
        return True

    def movement_input(self):
        keys = pygame.key.get_pressed()
        dx = (keys[pygame.K_d] or keys[pygame.K_RIGHT]) - (keys[pygame.K_a] or keys[pygame.K_LEFT])
        dy = (keys[pygame.K_s] or keys[pygame.K_DOWN]) - (keys[pygame.K_w] or keys[pygame.K_UP])
        if self.joystick_origin and self.joystick_pos:
            jx = self.joystick_pos[0] - self.joystick_origin[0]
            jy = self.joystick_pos[1] - self.joystick_origin[1]
            if length(jx, jy) > 8:
                dx, dy = norm(jx, jy)
        dx, dy = norm(dx, dy)
        if dx or dy:
            self.player.last_dx, self.player.last_dy = dx, dy
        return dx, dy

    def update_aim(self, dt):
        cam_x, cam_y = self.camera()
        mx, my = pygame.mouse.get_pos()
        if 0 <= mx <= WIDTH and 0 <= my <= HEIGHT and not self.joystick_origin:
            target_x = clamp(cam_x + mx, 0, WORLD_W)
            target_y = clamp(cam_y + my, 0, WORLD_H)
            follow = min(1, 1 - math.pow(0.001, dt))
            self.player.aim_x += (target_x - self.player.aim_x) * follow
            self.player.aim_y += (target_y - self.player.aim_y) * follow
            self.mouse_aim_active = True
        elif not self.mouse_aim_active:
            self.player.aim_x = self.player.x + self.player.last_dx * 160
            self.player.aim_y = self.player.y + self.player.last_dy * 160

        dx, dy = norm(self.player.aim_x - self.player.x, self.player.aim_y - self.player.y)
        if dx or dy:
            self.player.aim_dx = dx
            self.player.aim_dy = dy

    def aim_angle(self):
        return math.atan2(self.player.aim_dy, self.player.aim_dx)

    def update(self, dt):
        if self.state != "playing":
            return

        self.time_alive += dt
        self.wave = 1 + int(self.time_alive // 30)
        self.spawn_timer -= dt
        self.event_timer -= dt
        self.event_warning_time = max(0, self.event_warning_time - dt)
        self.event_time = max(0, self.event_time - dt)
        if self.event_objective:
            self.update_event_objective()
        if self.event_time <= 0 and self.event_objective:
            self.fail_event_objective()
        if self.event_time <= 0 and self.event_name:
            self.event_name = ""
        self.story_time = max(0, self.story_time - dt)
        self.relic_storm_timer = max(0, self.relic_storm_timer - dt)
        self.portal_timer = max(0, self.portal_timer - dt)
        self.player.invuln = max(0, self.player.invuln - dt)
        self.shake = max(0, self.shake - 28 * dt)
        self.flash = max(0, self.flash - 3.8 * dt)
        self.player.hp = min(self.player.max_hp, self.player.hp + self.player.regen * dt)
        dx, dy = self.movement_input()
        self.player.x = clamp(self.player.x + dx * self.player.speed * dt, self.player.radius, WORLD_W - self.player.radius)
        self.player.y = clamp(self.player.y + dy * self.player.speed * dt, self.player.radius, WORLD_H - self.player.radius)
        self.player.x, self.player.y = self.resolve_circle(self.player.x, self.player.y, self.player.radius)
        self.update_aim(dt)

        if self.time_alive >= self.win_time and not self.infinite_mode:
            self.finalize_run(True)
            self.state = "victory"
            return

        if self.next_boss_time and self.time_alive >= self.next_boss_time:
            self.spawn_boss()
            self.next_boss_time += 120
        if self.next_miniboss_time and self.time_alive >= self.next_miniboss_time:
            self.spawn_miniboss()
            self.next_miniboss_time += 75
        if self.next_merchant_time and self.time_alive >= self.next_merchant_time:
            self.spawn_merchant()
            self.next_merchant_time += 150
        if self.next_portal_time and self.time_alive >= self.next_portal_time:
            self.spawn_portal()
            self.next_portal_time += 170
        if self.next_story_time and self.time_alive >= self.next_story_time:
            self.story_text = random.choice(NARRATIVE_LINES)
            self.story_time = 7
            self.replay_events.append((int(self.time_alive), self.story_text))
            self.next_story_time += random.uniform(55, 90)

        if self.event_timer <= 4 and not self.pending_event:
            self.pending_event = random.choice(("Chuva de meteoros", "Neblina", "Horda elite", "Eclipse", "Tesouro errante", "Cristais perdidos"))
            self.event_warning_time = 4
            self.play_sound("boss", 0.16, 0.8)
        if self.event_timer <= 0:
            self.start_arena_event()
        if self.relic_storm_timer > 0 and random.random() < 0.025:
            weapon = self.weapons.get("lightning", Weapon("lightning", 2, self.base_cooldown("lightning")))
            self.fire_lightning(weapon)
        self.update_dynamic_music()

        interval = max(0.10, 0.74 - self.time_alive * 0.0022)
        if self.event_name == "Horda elite":
            interval *= 0.62
        if self.spawn_timer <= 0:
            amount = 1 + max(0, self.wave - 1) // 4
            if self.time_alive > 180:
                amount += 1
            if self.event_name == "Horda elite":
                amount += 2
            for _ in range(amount):
                if len(self.enemies) < MAX_ENEMIES:
                    self.spawn_enemy(elite=self.event_name == "Horda elite" and random.random() < 0.16)
            self.spawn_timer = interval

        self.update_weapons(dt)
        self.update_projectiles(dt)
        self.update_enemies(dt)
        self.update_gems(dt)
        self.update_chests()
        self.update_altars()
        self.update_merchants()
        self.update_portals()
        self.update_pets(dt)
        self.update_particles(dt)
        self.update_effects(dt)

        if self.player.hp <= 0:
            self.finalize_run(False)
            self.state = "game_over"

    def update_dynamic_music(self):
        if any(enemy.kind.startswith("boss") for enemy in self.enemies):
            self.set_music("boss")
        else:
            self.set_music(self.biome_at(self.player.x, self.player.y))

    def start_arena_event(self):
        self.event_timer = random.uniform(28, 42)
        self.event_name = self.pending_event or random.choice(("Chuva de meteoros", "Neblina", "Horda elite", "Eclipse", "Tesouro errante", "Cristais perdidos"))
        self.pending_event = ""
        self.event_warning_time = 0
        self.event_time = 12
        if self.event_name == "Chuva de meteoros":
            self.start_event_objective("survive", 12, 12, "Sobreviva")
            for _ in range(10 + min(8, self.wave)):
                self.make_explosion(random.uniform(80, WORLD_W - 80), random.uniform(80, WORLD_H - 80), 70, 28, ORANGE)
        elif self.event_name == "Neblina":
            self.start_event_objective("survive", 14, 14, "Aguente a neblina")
            self.event_time = 14
        elif self.event_name == "Horda elite":
            self.start_event_objective("kills", 12 + min(8, self.wave), 20, "Derrote a horda")
            for _ in range(6 + min(5, self.wave // 2)):
                if len(self.enemies) < MAX_ENEMIES:
                    self.spawn_enemy(elite=True)
        elif self.event_name == "Eclipse":
            self.start_event_objective("elite_kills", 4 + min(4, self.wave // 3), 20, "Derrube elites")
            for _ in range(7 + min(5, self.wave // 2)):
                if len(self.enemies) < MAX_ENEMIES:
                    self.spawn_enemy(elite=random.random() < 0.35)
        elif self.event_name == "Tesouro errante":
            self.start_event_objective("open_chest", 1, 18, "Abra o tesouro")
            x, y = self.spawn_position(180)
            self.chests.append(Chest(x, y))
        elif self.event_name == "Cristais perdidos":
            self.start_event_objective("collect", 6, 18, "Colete cristais")
            for i in range(8):
                angle = math.tau * i / 8
                dist = random.uniform(120, 260)
                x = clamp(self.player.x + math.cos(angle) * dist, 32, WORLD_W - 32)
                y = clamp(self.player.y + math.sin(angle) * dist, 32, WORLD_H - 32)
                if self.map_zone_at(x, y) != "lake":
                    self.gems.append(Gem(x, y, 9, 9, "event"))
        self.replay_events.append((int(self.time_alive), self.event_name))

    def start_event_objective(self, kind, target, duration, label):
        self.event_time = duration
        self.event_objective = {"kind": kind, "target": target, "value": 0, "label": label}
        self.story_text = f"Evento: {label}"
        self.story_time = 4

    def update_event_objective(self):
        if not self.event_objective:
            return
        if self.event_objective["kind"] == "survive":
            self.event_objective["value"] = self.event_objective["target"] - self.event_time
            if self.event_time <= 0:
                self.complete_event_objective()

    def advance_event_objective(self, kind, amount=1, elite=False):
        objective = self.event_objective
        if not objective:
            return
        if objective["kind"] == kind or (objective["kind"] == "elite_kills" and kind == "kills" and elite):
            objective["value"] += amount
            if objective["value"] >= objective["target"]:
                self.complete_event_objective()

    def complete_event_objective(self):
        if not self.event_objective:
            return
        reward = 35 + self.wave * 6
        self.run_coins += reward
        self.chests.append(Chest(self.player.x + random.uniform(-36, 36), self.player.y + random.uniform(-36, 36)))
        self.floating_text.append([self.player.x, self.player.y - 58, f"Evento concluido +{reward}", 1.4, GOLD])
        self.run_unlocked.append(f"Evento: {self.event_name}")
        self.replay_events.append((int(self.time_alive), f"Concluiu {self.event_name}"))
        self.play_sound("chest", 0.45, 0.25)
        self.event_objective = None
        self.event_time = min(self.event_time, 2.2)

    def fail_event_objective(self):
        if not self.event_objective:
            return
        self.floating_text.append([self.player.x, self.player.y - 54, "Evento falhou", 1.2, MUTED])
        self.replay_events.append((int(self.time_alive), f"Falhou {self.event_name}"))
        self.event_objective = None

    def event_progress_text(self):
        objective = self.event_objective
        if not objective:
            return ""
        if objective["kind"] == "survive":
            return f"{objective['label']}: {int(self.event_time)}s"
        return f"{objective['label']}: {int(objective['value'])}/{objective['target']} ({int(self.event_time)}s)"

    def damage_value(self, base):
        return base * self.player.damage_mult

    def cooldown_value(self, base):
        return max(0.08, base * self.player.cooldown_mult)

    def closest_enemy(self, x=None, y=None):
        if not self.enemies:
            return None
        x = self.player.x if x is None else x
        y = self.player.y if y is None else y
        return min(self.enemies, key=lambda e: (e.x - x) ** 2 + (e.y - y) ** 2)

    def weapon_is_evolved(self, key):
        weapon = self.weapons.get(key)
        return bool(weapon and weapon.evolved)

    def update_weapons(self, dt):
        for weapon in self.weapons.values():
            weapon.timer -= dt
            if weapon.timer <= 0:
                getattr(self, f"fire_{weapon.key}")(weapon)
                weapon.timer = self.cooldown_value(weapon.cooldown)

    def add_projectile(self, x, y, vx, vy, radius, damage, ttl, pierce, color, kind="bolt", explode_radius=0, source=""):
        self.projectiles.append(Projectile(x, y, vx, vy, radius, damage, ttl, pierce, color, kind, explode_radius, source))

    def fire_wand(self, weapon):
        self.weapon_sound("wand", 0.22, 0.08)
        count = 1 + weapon.level // 3 + (1 if weapon.evolved else 0)
        base = self.aim_angle()
        for i in range(count):
            offset = (i - (count - 1) / 2) * 0.08 + random.uniform(-0.025, 0.025)
            dx, dy = math.cos(base + offset), math.sin(base + offset)
            kind = "homing" if weapon.evolved else "bolt"
            self.add_projectile(self.player.x + dx * 22, self.player.y + dy * 22, dx * 570, dy * 570, 7 if weapon.evolved else 6, self.damage_value(17 + weapon.level * 4), 1.65 if weapon.evolved else 1.45, 1 + weapon.level // 4, CYAN, kind=kind, source="wand")

    def fire_orbit(self, weapon):
        self.weapon_sound("book" if weapon.evolved else "wand", 0.12, 0.3)
        count = 2 + weapon.level // 2 + (2 if weapon.evolved else 0)
        for i in range(count):
            angle = math.tau * i / count
            self.projectiles.append(Projectile(self.player.x, self.player.y, 0, 0, 13 if weapon.evolved else 10, self.damage_value(9 + weapon.level * 2), 6.4 if weapon.evolved else 5.2, 999, VIOLET, "orbit", 0, "orbit", angle, 72 + weapon.level * 8 if weapon.evolved else 54 + weapon.level * 7, 0))

    def fire_knife(self, weapon):
        self.weapon_sound("knife", 0.18, 0.08)
        count = 2 + weapon.level // 2 + (2 if weapon.evolved else 0)
        spread = 0.18
        base = self.aim_angle()
        for i in range(count):
            offset = (i - (count - 1) / 2) * spread
            dx, dy = math.cos(base + offset), math.sin(base + offset)
            self.add_projectile(self.player.x + dx * 24, self.player.y + dy * 24, dx * 660, dy * 660, 5, self.damage_value(13 + weapon.level * 3), 1.05, 1 + weapon.level // 3, PINK, source="knife")
        if weapon.evolved:
            for side in (-1, 1):
                angle = base + side * math.pi / 2
                dx, dy = math.cos(angle), math.sin(angle)
                self.add_projectile(self.player.x + dx * 18, self.player.y + dy * 18, dx * 610, dy * 610, 5, self.damage_value(12 + weapon.level * 2), 0.9, 2, PINK, source="knife")

    def fire_axe(self, weapon):
        self.weapon_sound("axe", 0.24, 0.1)
        dx, dy = self.player.aim_dx, self.player.aim_dy
        kind = "axe_evolved" if weapon.evolved else "bolt"
        self.add_projectile(self.player.x, self.player.y, dx * 290, dy * 290, 16 if weapon.evolved else 13, self.damage_value(36 + weapon.level * 7), 2.4, 5 + weapon.level // 2 if weapon.evolved else 4 + weapon.level // 2, GOLD, kind=kind, explode_radius=48 if weapon.evolved else 0, source="axe")

    def fire_lightning(self, weapon):
        if not self.enemies:
            return
        self.weapon_sound("lightning", 0.2, 0.15)
        hits = 1 + weapon.level // 2 + (2 if weapon.evolved else 0)
        for enemy in random.sample(self.enemies, min(hits, len(self.enemies))):
            self.damage_enemy(enemy, self.damage_value(30 + weapon.level * 6), CYAN, "lightning")
            self.add_effect(enemy.x, enemy.y, "bolt", CYAN, 46, 0.22)
            if weapon.evolved:
                for nearby in sorted(self.enemies, key=lambda e: length(e.x - enemy.x, e.y - enemy.y))[:2]:
                    if nearby is not enemy and length(nearby.x - enemy.x, nearby.y - enemy.y) < 190:
                        self.damage_enemy(nearby, self.damage_value(14 + weapon.level * 3), CYAN, "lightning")
                        self.add_effect(nearby.x, nearby.y, "ring", CYAN, 28, 0.16)
            for _ in range(10):
                self.particles.append(Particle(enemy.x, enemy.y, random.uniform(-100, 100), random.uniform(-100, 100), 0.2, CYAN, 3))

    def fire_bomb(self, weapon):
        target = self.closest_enemy()
        if not target:
            return
        self.weapon_sound("bomb", 0.2, 0.12)
        base = math.atan2(target.y - self.player.y, target.x - self.player.x)
        count = 3 if weapon.evolved else 1
        for i in range(count):
            angle = base + (i - (count - 1) / 2) * 0.28
            dx, dy = math.cos(angle), math.sin(angle)
            self.add_projectile(self.player.x, self.player.y, dx * 360, dy * 360, 10 if weapon.evolved else 9, self.damage_value(18 + weapon.level * 4), 1.15, 1, ORANGE, "bomb", 74 + weapon.level * 7 if weapon.evolved else 62 + weapon.level * 7, "bomb")

    def fire_boomerang(self, weapon):
        self.weapon_sound("knife", 0.17, 0.1)
        count = 1 + weapon.level // 4 + (1 if weapon.evolved else 0)
        base = self.aim_angle()
        for i in range(count):
            angle = base + (i - (count - 1) / 2) * 0.22
            dx, dy = math.cos(angle), math.sin(angle)
            pierce = 3 + weapon.level // 2 + self.precise_pierce_bonus() + (2 if weapon.evolved else 0)
            damage = self.damage_value(20 + weapon.level * 4)
            self.add_projectile(self.player.x + dx * 28, self.player.y + dy * 28, dx * (500 if weapon.evolved else 430), dy * (500 if weapon.evolved else 430), 11 if weapon.evolved else 8, damage, 1.55 if weapon.evolved else 1.35, pierce, GOLD, "boomerang", 0, "boomerang")

    def fire_drone(self, weapon):
        count = 1 + weapon.level // 4 + (1 if weapon.evolved else 0)
        for i in range(count):
            angle = self.time_alive * 2.3 + i * math.tau / count
            ox = self.player.x + math.cos(angle) * 72
            oy = self.player.y + math.sin(angle) * 72
            target = self.closest_enemy(ox, oy)
            if target:
                self.weapon_sound("drone", 0.13, 0.12)
                base = math.atan2(target.y - oy, target.x - ox)
                shots = (-0.08, 0.08) if weapon.evolved else (0,)
                for offset in shots:
                    dx, dy = math.cos(base + offset), math.sin(base + offset)
                    self.add_projectile(ox, oy, dx * 640, dy * 640, 5, self.damage_value(11 + weapon.level * 3), 1.1, 1, GREEN, source="drone")

    def fire_spear(self, weapon):
        self.weapon_sound("spear", 0.2, 0.1)
        count = 1 + weapon.level // 4 + (1 if weapon.evolved else 0)
        base = self.aim_angle()
        for i in range(count):
            angle = base + (i - (count - 1) / 2) * 0.12
            dx, dy = math.cos(angle), math.sin(angle)
            pierce = 3 + weapon.level // 2 + self.precise_pierce_bonus() + (3 if weapon.evolved else 0)
            self.add_projectile(self.player.x + dx * 24, self.player.y + dy * 24, dx * (820 if weapon.evolved else 720), dy * (820 if weapon.evolved else 720), 10 if weapon.evolved else 7, self.damage_value(24 + weapon.level * 5), 1.45 if weapon.evolved else 1.35, pierce, TEXT, source="spear")

    def fire_book(self, weapon):
        self.weapon_sound("book", 0.14, 0.35)
        count = 3 + weapon.level // 2 + (2 if weapon.evolved else 0)
        for i in range(count):
            angle = math.tau * i / count + self.time_alive
            self.projectiles.append(Projectile(self.player.x, self.player.y, 0, 0, 10 if weapon.evolved else 8, self.damage_value(12 + weapon.level * 3), 5.8 if weapon.evolved else 4.6, 999, PINK, "orbit", 0, "book", angle, 106 + weapon.level * 7 if weapon.evolved else 82 + weapon.level * 6, 0))

    def fire_flame(self, weapon):
        self.weapon_sound("flame", 0.18, 0.25)
        radius = 74 + weapon.level * 10 + (40 if weapon.evolved else 0)
        self.make_explosion(self.player.x, self.player.y, radius, self.damage_value(22 + weapon.level * 4), ORANGE, source="flame")
        if weapon.evolved:
            for i in range(4):
                angle = math.tau * i / 4 + self.time_alive
                self.make_explosion(self.player.x + math.cos(angle) * 92, self.player.y + math.sin(angle) * 92, 42, self.damage_value(12 + weapon.level * 2), GOLD, source="flame")

    def fire_scythe(self, weapon):
        self.weapon_sound("scythe", 0.22, 0.12)
        base = self.aim_angle()
        angles = (base - 0.24, base, base + 0.24) if weapon.evolved else (base,)
        for angle in angles:
            dx, dy = math.cos(angle), math.sin(angle)
            self.add_projectile(self.player.x + dx * 35, self.player.y + dy * 35, dx * 420, dy * 420, 20 if weapon.evolved else 18, self.damage_value(42 + weapon.level * 8), 1.25, 7 + weapon.level if weapon.evolved else 6 + weapon.level, VIOLET, source="scythe")

    def fire_chain(self, weapon):
        if not self.enemies:
            return
        self.weapon_sound("chain", 0.2, 0.14)
        jumps = 2 + weapon.level // 2 + (3 if weapon.evolved else 0)
        current = self.closest_enemy()
        hit = set()
        for _ in range(jumps):
            if not current or id(current) in hit:
                break
            hit.add(id(current))
            self.damage_enemy(current, self.damage_value(20 + weapon.level * 4), CYAN, "chain")
            self.add_effect(current.x, current.y, "ring", CYAN, 36, 0.2)
            if weapon.evolved:
                self.make_explosion(current.x, current.y, 34, self.damage_value(8 + weapon.level * 2), CYAN, source="chain")
            for _ in range(6):
                self.particles.append(Particle(current.x, current.y, random.uniform(-80, 80), random.uniform(-80, 80), 0.18, CYAN, 3))
            nearby = [e for e in self.enemies if id(e) not in hit and length(e.x - current.x, e.y - current.y) < 220]
            current = min(nearby, key=lambda e: length(e.x - current.x, e.y - current.y), default=None)

    def update_projectiles(self, dt):
        for projectile in self.projectiles[:]:
            if projectile.kind == "enemy":
                projectile.x += projectile.vx * dt
                projectile.y += projectile.vy * dt
                projectile.ttl -= dt
                if length(self.player.x - projectile.x, self.player.y - projectile.y) < self.player.radius + projectile.radius:
                    self.damage_player(projectile.damage)
                    if projectile in self.projectiles:
                        self.projectiles.remove(projectile)
                    continue
                if projectile.ttl <= 0 or not (-120 <= projectile.x <= WORLD_W + 120 and -120 <= projectile.y <= WORLD_H + 120):
                    if projectile in self.projectiles:
                        self.projectiles.remove(projectile)
                    continue
            elif projectile.kind == "orbit":
                projectile.ttl -= dt
                projectile.hit_cd = max(0, projectile.hit_cd - dt)
                owner = self.weapons.get(projectile.source)
                level = owner.level if owner else 1
                projectile.angle += dt * (2.8 + level * 0.18)
                projectile.x = self.player.x + math.cos(projectile.angle) * projectile.orbit_radius
                projectile.y = self.player.y + math.sin(projectile.angle) * projectile.orbit_radius
                if projectile.ttl <= 0:
                    self.projectiles.remove(projectile)
                    continue
            else:
                if projectile.kind == "homing":
                    target = self.closest_enemy(projectile.x, projectile.y)
                    if target and length(target.x - projectile.x, target.y - projectile.y) < 360:
                        dx, dy = norm(target.x - projectile.x, target.y - projectile.y)
                        speed = max(420, length(projectile.vx, projectile.vy))
                        projectile.vx = projectile.vx * 0.84 + dx * speed * 0.16
                        projectile.vy = projectile.vy * 0.84 + dy * speed * 0.16
                if projectile.kind == "boomerang" and projectile.ttl < 0.72:
                    dx, dy = norm(self.player.x - projectile.x, self.player.y - projectile.y)
                    speed = 470
                    projectile.vx = projectile.vx * 0.72 + dx * speed * 0.28
                    projectile.vy = projectile.vy * 0.72 + dy * speed * 0.28
                projectile.x += projectile.vx * dt
                projectile.y += projectile.vy * dt
                projectile.ttl -= dt
                if projectile.ttl <= 0 or not (-120 <= projectile.x <= WORLD_W + 120 and -120 <= projectile.y <= WORLD_H + 120):
                    if projectile.kind == "bomb":
                        self.make_explosion(projectile.x, projectile.y, projectile.explode_radius, projectile.damage, ORANGE, source=projectile.source)
                    if projectile in self.projectiles:
                        self.projectiles.remove(projectile)
                    continue

            for item in self.breakables[:]:
                if length(item.x - projectile.x, item.y - projectile.y) < item.radius + projectile.radius:
                    self.damage_breakable(item, projectile.damage)
                    if projectile.kind == "bomb":
                        self.make_explosion(projectile.x, projectile.y, projectile.explode_radius, projectile.damage, ORANGE, source=projectile.source)
                        if projectile in self.projectiles:
                            self.projectiles.remove(projectile)
                        break
                    if projectile.kind != "orbit":
                        projectile.pierce -= 1
                        if projectile.pierce <= 0 and projectile in self.projectiles:
                            self.projectiles.remove(projectile)
                            break
            if projectile not in self.projectiles:
                continue

            for enemy in self.enemies[:]:
                if length(enemy.x - projectile.x, enemy.y - projectile.y) < enemy.radius + projectile.radius:
                    if projectile.kind == "orbit" and projectile.hit_cd > 0:
                        continue
                    self.damage_enemy(enemy, projectile.damage, projectile.color, projectile.source)
                    if projectile.kind == "bomb":
                        self.make_explosion(projectile.x, projectile.y, projectile.explode_radius, projectile.damage, ORANGE, source=projectile.source)
                        if projectile in self.projectiles:
                            self.projectiles.remove(projectile)
                        break
                    if projectile.kind == "axe_evolved":
                        self.make_explosion(projectile.x, projectile.y, projectile.explode_radius, projectile.damage * 0.35, GOLD, source=projectile.source)
                    if projectile.kind == "orbit":
                        projectile.hit_cd = 0.22
                        break
                    projectile.pierce -= 1
                    if projectile.pierce <= 0 and projectile in self.projectiles:
                        self.projectiles.remove(projectile)
                    break

    def update_enemies(self, dt):
        for enemy in self.enemies[:]:
            enemy.cooldown = max(0, enemy.cooldown - dt)
            enemy.hit_flash = max(0, enemy.hit_flash - dt)
            if abs(enemy.knock_x) > 1 or abs(enemy.knock_y) > 1:
                enemy.x += enemy.knock_x * dt
                enemy.y += enemy.knock_y * dt
                enemy.knock_x *= max(0, 1 - 8 * dt)
                enemy.knock_y *= max(0, 1 - 8 * dt)
            dx, dy = norm(self.player.x - enemy.x, self.player.y - enemy.y)
            dist = length(self.player.x - enemy.x, self.player.y - enemy.y)

            if enemy.windup > 0:
                enemy.windup = max(0, enemy.windup - dt)
                if enemy.windup <= 0:
                    if enemy.kind == "archer":
                        sx, sy = norm(enemy.target_x - enemy.x, enemy.target_y - enemy.y)
                        if sx or sy:
                            self.add_projectile(enemy.x, enemy.y, sx * 360, sy * 360, 5, enemy.damage, 2.1, 1, RED, "enemy", source="enemy")
                        enemy.cooldown = 1.8
                    elif enemy.kind == "exploder":
                        self.make_explosion(enemy.x, enemy.y, 84, enemy.damage, ORANGE, hurts_player=True, source="enemy")
                        self.kill_enemy(enemy, drop=False)
                        continue
                    elif enemy.kind == "summoner" and len(self.enemies) < MAX_ENEMIES:
                        nearby_count = sum(1 for other in self.enemies if other.kind == "runner" and length(other.x - enemy.x, other.y - enemy.y) < 260)
                        for _ in range(max(0, min(3, 6 - nearby_count))):
                            sx = clamp(enemy.x + random.uniform(-72, 72), 24, WORLD_W - 24)
                            sy = clamp(enemy.y + random.uniform(-72, 72), 24, WORLD_H - 24)
                            self.enemies.append(Enemy(sx, sy, 12, 18 + self.wave * 2, 118, 8, 2, "runner"))
                        enemy.cooldown = 4.4
                    elif enemy.kind in ("boss", "boss_warlock", "boss_frost", "miniboss"):
                        shots = 12 if enemy.kind == "boss" else (8 if enemy.kind != "miniboss" else 5)
                        color = RED if enemy.kind == "boss" else (VIOLET if enemy.kind == "boss_warlock" else CYAN)
                        spread = math.tau / shots
                        for i in range(shots):
                            angle = spread * i + self.time_alive * 0.35
                            self.add_projectile(enemy.x, enemy.y, math.cos(angle) * 250, math.sin(angle) * 250, 6, enemy.damage * 0.55, 2.4, 1, color, "enemy", source="enemy")
                        enemy.cooldown = 2.5 if enemy.kind != "miniboss" else 3.2
                else:
                    slow = 0.18 if enemy.kind in ("exploder", "summoner") else 0.05
                    enemy.x += dx * enemy.speed * slow * dt
                    enemy.y += dy * enemy.speed * slow * dt
                    enemy.x, enemy.y = self.resolve_circle(enemy.x, enemy.y, enemy.radius)
                    continue

            if enemy.kind == "archer" and dist < 380:
                if enemy.cooldown <= 0:
                    enemy.windup = enemy.windup_total = 0.42
                    enemy.target_x, enemy.target_y = self.player.x, self.player.y
                    self.add_effect(enemy.x, enemy.y, "ring", PINK, 28, 0.28)
                if dist < 250:
                    enemy.x -= dx * enemy.speed * 0.48 * dt
                    enemy.y -= dy * enemy.speed * 0.48 * dt
                else:
                    enemy.x += -dy * enemy.speed * 0.22 * dt
                    enemy.y += dx * enemy.speed * 0.22 * dt
            elif enemy.kind == "exploder" and dist < 105 and enemy.cooldown <= 0:
                enemy.windup = enemy.windup_total = 0.62
                enemy.target_x, enemy.target_y = enemy.x, enemy.y
                enemy.cooldown = 2.0
                self.add_effect(enemy.x, enemy.y, "ring", ORANGE, 84, 0.45)
            elif enemy.kind == "summoner" and enemy.cooldown <= 0 and len(self.enemies) < MAX_ENEMIES:
                enemy.windup = enemy.windup_total = 0.55
                enemy.target_x, enemy.target_y = enemy.x, enemy.y
                self.add_effect(enemy.x, enemy.y, "ring", VIOLET, 58, 0.45)
            elif enemy.kind in ("boss", "boss_warlock", "boss_frost", "miniboss") and enemy.cooldown <= 0:
                enemy.windup = enemy.windup_total = 0.68 if enemy.kind != "miniboss" else 0.52
                enemy.target_x, enemy.target_y = self.player.x, self.player.y
                self.add_effect(enemy.x, enemy.y, "ring", self.enemy_color(enemy), enemy.radius + 34, 0.5)
            else:
                enemy.x += dx * enemy.speed * dt
                enemy.y += dy * enemy.speed * dt
            enemy.x, enemy.y = self.resolve_circle(enemy.x, enemy.y, enemy.radius)

            if dist < enemy.radius + self.player.radius:
                if enemy.kind == "exploder":
                    if enemy.windup <= 0:
                        enemy.windup = enemy.windup_total = 0.36
                        enemy.cooldown = 2.0
                    continue
                self.damage_player(enemy.damage)

    def update_gems(self, dt):
        for gem in self.gems[:]:
            dist = length(gem.x - self.player.x, gem.y - self.player.y)
            if dist < self.player.pickup_radius:
                dx, dy = norm(self.player.x - gem.x, self.player.y - gem.y)
                pull = 260 + (self.player.pickup_radius - dist) * 5
                gem.x += dx * pull * dt
                gem.y += dy * pull * dt
            if dist < self.player.radius + gem.radius:
                self.gems.remove(gem)
                if gem.kind == "event":
                    self.advance_event_objective("collect")
                    self.score += gem.value * 12
                    self.play_sound("pickup", 0.22, 0.04)
                    self.add_effect(gem.x, gem.y, "pickup", CYAN, 34, 0.24)
                    self.burst_particles(gem.x, gem.y, CYAN, 8, 40, 150, 0.24, (2, 4))
                    continue
                xp_gain = 1 + self.progress["permanent_upgrades"].get("xp_gain", 0) * 0.05 + self.run_xp_bonus
                self.player.xp += int(gem.value * xp_gain)
                self.score += gem.value * 10
                self.play_sound("pickup", 0.18, 0.04)
                if gem.value >= 5 or random.random() < 0.2:
                    self.add_effect(gem.x, gem.y, "pickup", CYAN, 26, 0.18)
                while self.player.xp >= self.player.xp_to_level:
                    self.level_up()
                    if self.state == "upgrade":
                        break

    def update_chests(self):
        for chest in self.chests[:]:
            if length(chest.x - self.player.x, chest.y - self.player.y) < chest.radius + self.player.radius + 8:
                self.chests.remove(chest)
                self.advance_event_objective("open_chest")
                self.open_chest()
                break

    def spawn_merchant(self):
        x, y = self.spawn_position(160)
        self.merchants.append(Merchant(x, y))
        self.story_text = "Um mercador acende uma lanterna na escuridao."
        self.story_time = 5

    def update_merchants(self):
        for merchant in self.merchants[:]:
            if merchant.active and length(merchant.x - self.player.x, merchant.y - self.player.y) < merchant.radius + self.player.radius + 12:
                cost = 90
                if self.progress["coins"] >= cost:
                    self.progress["coins"] -= cost
                    merchant.active = False
                    self.open_chest()
                    self.run_unlocked.append("Compra do mercador")
                    self.save_progress()
                else:
                    self.floating_text.append([merchant.x, merchant.y - 28, "Precisa 90 moedas", 1.0, GOLD])
                    merchant.active = False

    def spawn_portal(self):
        x, y = self.spawn_position(180)
        self.portals.append(Portal(x, y))
        self.story_text = "Um portal instavel rasga o mapa."
        self.story_time = 5

    def update_portals(self):
        for portal in self.portals[:]:
            if portal.active and length(portal.x - self.player.x, portal.y - self.player.y) < portal.radius + self.player.radius + 10:
                portal.active = False
                self.portal_timer = 25
                self.portal_kills = 0
                self.event_name = "Arena especial"
                self.event_time = 25
                self.replay_events.append((int(self.time_alive), "Entrou em arena especial"))
                for _ in range(16):
                    if len(self.enemies) < MAX_ENEMIES:
                        self.spawn_enemy(elite=random.random() < 0.25)
            if not portal.active and portal in self.portals:
                self.portals.remove(portal)

    def update_pets(self, dt):
        for pet in self.pets:
            angle = self.time_alive * 2.1
            target_x = self.player.x + math.cos(angle) * 58
            target_y = self.player.y + math.sin(angle) * 58
            pet.x += (target_x - pet.x) * min(1, dt * 6)
            pet.y += (target_y - pet.y) * min(1, dt * 6)
            pet.cooldown -= dt
            if pet.cooldown <= 0 and self.enemies:
                target = self.closest_enemy(pet.x, pet.y)
                if target:
                    dx, dy = norm(target.x - pet.x, target.y - pet.y)
                    self.add_projectile(pet.x, pet.y, dx * 540, dy * 540, 5, self.damage_value(10), 1.1, 1, GREEN, source="pet")
                    pet.cooldown = 1.25

    def update_altars(self):
        for altar in self.altars:
            if altar.active and length(altar.x - self.player.x, altar.y - self.player.y) < altar.radius + self.player.radius + 10:
                altar.active = False
                if altar.kind == "heal":
                    self.player.hp = self.player.max_hp
                    self.floating_text.append([altar.x, altar.y - 30, "Altar da vida", 1.2, GREEN])
                elif altar.kind == "xp":
                    self.player.xp += self.player.xp_to_level // 2
                    if self.player.xp >= self.player.xp_to_level:
                        self.level_up()
                    self.floating_text.append([altar.x, altar.y - 30, "Conhecimento", 1.2, CYAN])
                elif altar.kind == "gold":
                    for _ in range(12):
                        self.gems.append(Gem(altar.x + random.uniform(-40, 40), altar.y + random.uniform(-40, 40), 6, 7))
                    self.floating_text.append([altar.x, altar.y - 30, "Tesouro antigo", 1.2, GOLD])
                elif altar.kind == "storm":
                    self.event_name = "Chuva de meteoros"
                    self.event_time = 10
                    for _ in range(18):
                        self.make_explosion(random.uniform(80, WORLD_W - 80), random.uniform(80, WORLD_H - 80), 76, 34, ORANGE)
                elif altar.kind == "elite":
                    self.event_name = "Horda elite"
                    self.event_time = 12
                    for _ in range(8):
                        if len(self.enemies) < MAX_ENEMIES:
                            self.spawn_enemy(elite=True)
                for _ in range(24):
                    angle = random.random() * math.tau
                    speed = random.uniform(60, 190)
                    self.particles.append(Particle(altar.x, altar.y, math.cos(angle) * speed, math.sin(angle) * speed, 0.45, GOLD, random.uniform(3, 6)))

    def update_particles(self, dt):
        for particle in self.particles[:]:
            particle.x += particle.vx * dt
            particle.y += particle.vy * dt
            particle.vx *= 0.92
            particle.vy *= 0.92
            particle.ttl -= dt
            if particle.ttl <= 0:
                self.particles.remove(particle)
        for item in self.floating_text[:]:
            item[1] -= 26 * dt
            item[3] -= dt
            if item[3] <= 0:
                self.floating_text.remove(item)

    def update_effects(self, dt):
        for effect in self.effects[:]:
            effect.ttl -= dt
            if effect.ttl <= 0:
                self.effects.remove(effect)

    def add_effect(self, x, y, kind, color, radius=48, duration=0.45):
        self.effects.append(VisualEffect(x, y, duration, duration, kind, color, radius))

    def burst_particles(self, x, y, color, count=8, speed_min=50, speed_max=180, ttl=0.28, radius=(2, 5)):
        for _ in range(count):
            angle = random.random() * math.tau
            speed = random.uniform(speed_min, speed_max)
            size = random.uniform(radius[0], radius[1]) if isinstance(radius, tuple) else radius
            self.particles.append(Particle(x, y, math.cos(angle) * speed, math.sin(angle) * speed, ttl * random.uniform(0.75, 1.25), color, size))

    def weapon_sound(self, key, volume=0.2, min_gap=0.08):
        self.play_sound(key if key in self.sounds else "shoot", volume, min_gap)

    def damage_player(self, amount):
        if self.player.invuln > 0:
            return
        damage = max(2, amount - self.player.armor)
        self.player.hp -= damage
        self.player.invuln = 0.55
        self.shake = max(self.shake, 8)
        self.flash = max(self.flash, 0.68)
        self.play_sound("hurt", 0.4, 0.18)
        self.add_effect(self.player.x, self.player.y, "hit", RED, 46, 0.24)
        self.floating_text.append([self.player.x, self.player.y - 42, f"-{int(damage)}", 0.75, RED])
        self.burst_particles(self.player.x, self.player.y, RED, 16, 70, 230, 0.32, (3, 6))

    def damage_enemy(self, enemy, damage, color, source="outros"):
        enemy.hp -= damage
        enemy.hit_flash = 0.12
        kx, ky = norm(enemy.x - self.player.x, enemy.y - self.player.y)
        force = clamp(damage * 3.8, 45, 260)
        enemy.knock_x += kx * force
        enemy.knock_y += ky * force
        key = source if source in self.damage_by_weapon else "outros"
        self.damage_by_weapon[key] += int(damage)
        self.hit_burst(enemy.x, enemy.y, color)
        if damage >= 36:
            self.shake = max(self.shake, min(7, damage / 12))
            self.add_effect(enemy.x, enemy.y, "hit", color, enemy.radius * 2.2, 0.18)
        if damage >= 28 or random.random() < 0.14:
            self.floating_text.append([enemy.x, enemy.y - enemy.radius, str(int(damage)), 0.55, color])
        if enemy.hp <= 0:
            self.kill_enemy(enemy)

    def make_explosion(self, x, y, radius, damage, color, hurts_player=False, source="outros"):
        self.shake = max(self.shake, min(12, radius / 7))
        self.flash = max(self.flash, 0.22)
        self.play_sound("boom", 0.38, 0.16)
        self.add_effect(x, y, "explosion", color, radius, 0.42)
        for enemy in self.enemies[:]:
            if length(enemy.x - x, enemy.y - y) < radius + enemy.radius:
                self.damage_enemy(enemy, damage, color, source)
        for item in self.breakables[:]:
            if length(item.x - x, item.y - y) < radius + item.radius:
                self.damage_breakable(item, damage)
        if hurts_player and length(self.player.x - x, self.player.y - y) < radius + self.player.radius:
            self.damage_player(damage)
        self.burst_particles(x, y, color, 26, 60, 230, 0.38, (3, 7))

    def biome_particle_color(self):
        return (75, 130, 78)

    def kill_enemy(self, enemy, drop=True):
        if enemy in self.enemies:
            self.enemies.remove(enemy)
        self.kills += 1
        self.score += 25 + enemy.xp * 5
        death_color = self.enemy_color(enemy)
        self.add_effect(enemy.x, enemy.y, "death", death_color, enemy.radius * 2.4, 0.38)
        self.add_effect(enemy.x, enemy.y, "shockwave", death_color, enemy.radius * (3.0 if enemy.elite else 2.0), 0.28)
        _label, _hp_mod, _speed_mod, coin_mod = self.difficulty_mods()
        map_coin = 1.35 if self.map_modifier in ("gold_rush", "blood_moon") else 1.0
        talent_coin = 1 + self.progress.get("talents", {}).get("growth", 0) * 0.04
        coins = int((2 + enemy.xp // 3 + (12 if enemy.elite else 0) + (35 if enemy.kind.startswith("boss") else 0)) * coin_mod * map_coin * talent_coin)
        self.run_coins += coins
        self.play_sound("hit", 0.2, 0.05)
        if drop:
            self.gems.append(Gem(enemy.x, enemy.y, enemy.xp, 8 if enemy.elite else 6))
        if enemy.kind.startswith("boss"):
            self.run_boss_kills += 1
            self.chests.append(Chest(enemy.x, enemy.y))
            self.shake = max(self.shake, 16)
            self.flash = max(self.flash, 0.55)
            self.play_sound("boss", 0.5, 0.4)
        elif enemy.elite and random.random() < 0.28:
            self.chests.append(Chest(enemy.x, enemy.y))
        self.burst_particles(enemy.x, enemy.y, GOLD if enemy.elite else VIOLET, 24 if enemy.elite else 10, 70, 260 if enemy.elite else 170, 0.42, (2, 6))
        if self.portal_timer > 0:
            self.portal_kills += 1
            if self.portal_kills >= 18:
                self.portal_timer = 0
                self.chests.append(Chest(enemy.x, enemy.y))
                self.run_unlocked.append("Arena especial concluida")
        self.advance_event_objective("kills", elite=enemy.elite)

    def hit_burst(self, x, y, color):
        self.burst_particles(x, y, color, 5, 45, 135, 0.18, (2, 4))

    def rarity_roll(self, chest=False):
        luck = self.player.luck + (0.35 if chest else 0)
        roll = random.random()
        if roll < 0.04 + luck * 0.05:
            return "lendario"
        if roll < 0.16 + luck * 0.10:
            return "epico"
        if roll < 0.45 + luck * 0.14:
            return "raro"
        return "comum"

    def cycle_difficulty(self, direction=1):
        keys = list(DIFFICULTIES)
        current = keys.index(self.difficulty) if self.difficulty in keys else 1
        self.difficulty = keys[(current + direction) % len(keys)]
        self.progress["difficulty"] = self.difficulty
        self.save_progress()
        self.play_sound("pickup", 0.3, 0.1)

    def level_up(self):
        self.player.xp -= self.player.xp_to_level
        self.player.level += 1
        self.player.xp_to_level = int(self.player.xp_to_level * 1.28 + 7)
        self.player.hp = min(self.player.max_hp, self.player.hp + max(8, self.player.max_hp * 0.08))
        self.state = "upgrade"
        self.upgrade_choices = self.make_upgrade_choices(False)
        self.shake = max(self.shake, 5)
        self.flash = max(self.flash, 0.28)
        self.add_effect(self.player.x, self.player.y, "level", CYAN, 120, 0.75)
        self.floating_text.append([self.player.x, self.player.y - 66, f"Nivel {self.player.level}", 1.0, CYAN])
        self.burst_particles(self.player.x, self.player.y, CYAN, 28, 80, 260, 0.5, (2, 5))
        self.play_sound("level", 0.48, 0.2)

    def open_chest(self):
        self.state = "chest"
        self.upgrade_choices = self.make_upgrade_choices(True)
        self.play_sound("chest", 0.52, 0.3)

    def make_upgrade_choices(self, chest):
        pool = []
        evolution_pool = []
        for key, (name, desc) in WEAPON_INFO.items():
            if key not in self.progress.get("unlocked_weapons", ["wand"]):
                continue
            weapon = self.weapons.get(key)
            if weapon is None:
                pool.append(("weapon_new", key, f"Nova arma: {name}", desc))
            elif weapon.level < 8:
                pool.append(("weapon_level", key, f"{name} Nv.{weapon.level + 1}", "Aumenta poder da arma"))
            elif not weapon.evolved:
                evo_name, evo_desc = EVOLUTION_INFO.get(key, ("Forma final", "Forma final da arma"))
                evolution_pool.append(("weapon_evolve", key, f"{evo_name}: {name}", evo_desc))
        for key, (name, desc) in PASSIVE_INFO.items():
            if self.passives[key] < 5:
                pool.append(("passive", key, f"{name} Nv.{self.passives[key] + 1}", desc))
        for key, (name, desc) in RELIC_INFO.items():
            if key in self.progress.get("unlocked_relics", []) and key not in self.relics:
                pool.append(("relic", key, name, desc))
        pool.extend(evolution_pool)
        pool = [item for item in pool if item[2] not in self.banned_upgrades]
        random.shuffle(pool)
        choices = []
        for item in pool[:3]:
            rarity = self.rarity_roll(chest)
            if item[0] == "weapon_evolve":
                rarity = "lendario"
            choices.append((*item, rarity))
        if evolution_pool and not any(item[0] == "weapon_evolve" for item in choices):
            available = [item for item in evolution_pool if item[2] not in self.banned_upgrades]
            if available:
                choices[-1:] = [(*random.choice(available), "lendario")]
        return choices

    def reroll_upgrades(self):
        if self.state not in ("upgrade", "chest") or self.rerolls <= 0:
            return
        cost = 25 * (3 - self.rerolls)
        if cost and self.progress["coins"] < cost:
            return
        self.progress["coins"] -= cost
        self.rerolls -= 1
        self.upgrade_choices = self.make_upgrade_choices(self.state == "chest")
        self.save_progress()
        self.play_sound("pickup", 0.25, 0.1)

    def banish_upgrade(self, index):
        if self.state not in ("upgrade", "chest") or self.banishes <= 0 or not self.upgrade_choices:
            return
        index = clamp(index, 0, len(self.upgrade_choices) - 1)
        _kind, _key, title, _desc, _rarity = self.upgrade_choices[index]
        self.banned_upgrades.append(title)
        self.banishes -= 1
        self.upgrade_choices = self.make_upgrade_choices(self.state == "chest")
        self.play_sound("hit", 0.18, 0.12)

    def pick_upgrade(self, index):
        if not self.upgrade_choices:
            return
        index = clamp(index, 0, len(self.upgrade_choices) - 1)
        kind, key, title, _desc, rarity = self.upgrade_choices[index]
        mult = RARITIES[rarity]["mult"]
        if kind == "weapon_new":
            self.weapons[key] = Weapon(key, 1, self.base_cooldown(key))
            self.refresh_synergies()
        elif kind == "weapon_level":
            self.weapons[key].level += 1
            self.weapons[key].cooldown = max(0.18, self.weapons[key].cooldown * (0.96 - 0.03 * (mult - 1)))
        elif kind == "weapon_evolve":
            self.weapons[key].evolved = True
            self.weapons[key].level = 9
            self.run_evolved += 1
            self.play_sound("evolve", 0.56, 0.3)
            self.play_sound("legendary", 0.5, 0.5)
            self.add_effect(self.player.x, self.player.y, "evolve", GOLD, 150, 1.1)
            self.shake = max(self.shake, 10)
            self.flash = max(self.flash, 0.48)
            self.burst_particles(self.player.x, self.player.y, GOLD, 42, 110, 320, 0.62, (3, 7))
        elif kind == "passive":
            self.passives[key] += 1
            self.apply_passive(key, mult)
        elif kind == "relic":
            self.apply_relic(key)
        if kind != "weapon_evolve":
            self.add_effect(self.player.x, self.player.y, "pickup", RARITIES[rarity]["color"], 76, 0.35)
            self.burst_particles(self.player.x, self.player.y, RARITIES[rarity]["color"], 12, 60, 190, 0.34, (2, 5))
        if rarity == "lendario":
            self.play_sound("legendary", 0.42, 0.4)
            self.add_effect(self.player.x, self.player.y, "legendary", RARITIES[rarity]["color"], 130, 0.85)
        self.floating_text.append([self.player.x, self.player.y - 44, title, 1.1, RARITIES[rarity]["color"]])
        self.state = "playing"
        self.upgrade_choices = []

    def base_cooldown(self, key):
        return {
            "wand": 0.76,
            "orbit": 4.6,
            "knife": 0.92,
            "axe": 1.8,
            "lightning": 2.1,
            "bomb": 1.9,
            "drone": 1.15,
            "spear": 1.05,
            "book": 3.8,
            "flame": 2.6,
            "scythe": 1.75,
            "chain": 2.15,
            "boomerang": 1.35,
        }[key]

    def apply_passive(self, key, mult):
        if key == "move":
            self.player.speed += 18 * mult
        elif key == "regen":
            self.player.regen += 0.18 * mult
            self.player.max_hp += 6 * mult
        elif key == "magnet":
            self.player.pickup_radius += 34 * mult
        elif key == "armor":
            self.player.armor += 1.4 * mult
        elif key == "luck":
            self.player.luck += 0.18 * mult
        elif key == "cooldown":
            self.player.cooldown_mult *= max(0.62, 1 - 0.045 * mult)

    def apply_relic(self, key):
        self.relics.append(key)
        if key == "blood_crown":
            self.player.damage_mult += 0.18
            self.player.max_hp = max(35, self.player.max_hp - 12)
            self.player.hp = min(self.player.hp, self.player.max_hp)
        elif key == "moon_shard":
            self.player.luck += 0.15
            self.run_xp_bonus += 0.25
        elif key == "phoenix_ember":
            self.player.regen += 0.35
            self.player.hp = min(self.player.max_hp, self.player.hp + 55)
        elif key == "storm_ring":
            self.relic_storm_timer = 28
            if "lightning" not in self.weapons:
                self.weapons["lightning"] = Weapon("lightning", 2, self.base_cooldown("lightning"))
        elif key == "giant_belt":
            self.player.max_hp += 35
            self.player.hp += 35
            self.player.armor += 2

    def buy_permanent_upgrade(self, index):
        keys = list(PERMANENT_UPGRADES)
        if index >= len(keys):
            return
        key = keys[index]
        name, _desc, base_cost = PERMANENT_UPGRADES[key]
        level = self.progress["permanent_upgrades"].get(key, 0)
        if level >= 10:
            return
        cost = base_cost + level * base_cost // 2
        if self.progress["coins"] >= cost:
            self.progress["coins"] -= cost
            self.progress["permanent_upgrades"][key] = level + 1
            self.save_progress()
            self.floating_text.append([self.player.x, self.player.y - 40, f"{name} comprado", 1.1, GOLD])
            self.play_sound("chest", 0.35, 0.2)

    def buy_talent(self, index):
        keys = list(TALENTS)
        if index >= len(keys):
            return
        key = keys[index]
        level = self.progress["talents"].get(key, 0)
        if level >= 6:
            return
        cost = TALENTS[key][2] + level
        if self.progress.get("prestige_points", 0) >= cost:
            self.progress["prestige_points"] -= cost
            self.progress["talents"][key] = level + 1
            self.save_progress()
            self.play_sound("chest", 0.35, 0.2)

    def do_prestige(self):
        if self.progress.get("best_time", 0) < 600 and self.progress.get("total_kills", 0) < 1000:
            return
        gained = max(1, self.progress.get("best_time", 0) // 300 + self.progress.get("total_kills", 0) // 500)
        keep = {
            "prestige": self.progress.get("prestige", 0) + 1,
            "prestige_points": self.progress.get("prestige_points", 0) + gained,
            "talents": self.progress.get("talents", {key: 0 for key in TALENTS}),
            "history": self.progress.get("history", []),
            "ranking": self.progress.get("ranking", []),
            "codex_seen": self.progress.get("codex_seen", {"enemies": [], "weapons": [], "relics": []}),
        }
        self.progress = self.default_progress()
        self.progress.update(keep)
        self.selected_character = "hunter"
        self.difficulty = "normal"
        self.save_progress()
        self.state = "menu"
        self.play_sound("evolve", 0.55, 0.4)

    def pick_character(self, index):
        keys = list(CHARACTERS)
        if index >= len(keys):
            return
        key = keys[index]
        if key in self.progress.get("unlocked_characters", []):
            self.selected_character = key
            self.progress["selected_character"] = key
            self.save_progress()
            self.play_sound("pickup", 0.3, 0.1)

    def unlock_item(self, collection, key):
        items = self.progress.setdefault(collection, [])
        if key not in items:
            items.append(key)
            if hasattr(self, "run_unlocked"):
                label = WEAPON_INFO.get(key, CHARACTERS.get(key, (key,))[0])[0] if key in WEAPON_INFO else CHARACTERS.get(key, (key,))[0]
                self.run_unlocked.append(label)
            return True
        return False

    def mark_codex(self, category, key):
        seen = self.progress.setdefault("codex_seen", {}).setdefault(category, [])
        if key not in seen:
            seen.append(key)

    def award_achievement(self, key):
        if key in self.progress["achievements"]:
            return
        self.progress["achievements"].append(key)
        if hasattr(self, "run_unlocked"):
            self.run_unlocked.append(ACHIEVEMENTS[key][0])
        reward = ACHIEVEMENTS[key][2]
        self.progress["coins"] += reward
        self.progress["total_coins"] += reward

    def update_unlocks(self):
        total_kills = self.progress["total_kills"]
        best_time = self.progress["best_time"]
        if total_kills >= 1:
            self.award_achievement("first_blood")
        if total_kills >= 100:
            self.award_achievement("hundred_kills")
            self.unlock_item("unlocked_weapons", "axe")
        if total_kills >= 500:
            self.award_achievement("five_hundred_kills")
        if self.progress["boss_kills"] >= 1:
            self.award_achievement("boss_down")
            self.unlock_item("unlocked_weapons", "bomb")
        if self.progress["boss_kills"] >= 5:
            self.award_achievement("boss_hunter")
        if best_time >= 300:
            self.award_achievement("survivor_5")
            self.unlock_item("unlocked_weapons", "drone")
        if best_time >= 600:
            self.award_achievement("survivor_10")
        if self.progress["evolved_weapons"] >= 1:
            self.award_achievement("evolved")
            self.unlock_item("unlocked_weapons", "lightning")
            self.unlock_item("unlocked_characters", "mage")
            self.unlock_item("unlocked_relics", "storm_ring")
        if self.active_synergies or any(record.get("synergies") for record in self.progress.get("history", [])):
            self.award_achievement("synergy")
        if self.progress["total_coins"] >= 500:
            self.award_achievement("rich")
        if self.progress["total_coins"] >= 1500:
            self.award_achievement("wealthy")
        if total_kills >= 250:
            self.unlock_item("unlocked_characters", "knight")
            self.unlock_item("unlocked_weapons", "scythe")
        if total_kills >= 400:
            self.unlock_item("unlocked_characters", "rogue")
            self.unlock_item("unlocked_weapons", "chain")
        if self.progress["boss_kills"] >= 3:
            self.unlock_item("unlocked_characters", "alchemist")
            self.unlock_item("unlocked_weapons", "flame")
            self.unlock_item("unlocked_relics", "phoenix_ember")
        if best_time >= 600:
            self.unlock_item("unlocked_characters", "monk")
            self.unlock_item("unlocked_weapons", "book")
            self.unlock_item("unlocked_relics", "giant_belt")

    def finalize_run(self, won):
        if self.run_finished_saved:
            return
        self.run_finished_saved = True
        bonus = 120 if won else 0
        performance_bonus = self.calculate_progression_bonus(won)
        earned = self.run_coins + bonus + performance_bonus + int(self.time_alive // 20)
        self.progress["coins"] += earned
        self.progress["total_coins"] += earned
        self.progress["total_kills"] += self.kills
        self.progress["best_time"] = max(self.progress["best_time"], int(self.time_alive))
        self.progress["boss_kills"] += self.run_boss_kills
        self.progress["evolved_weapons"] += self.run_evolved
        self.apply_character_objective_reward()
        self.apply_goal_reward(won)
        self.update_unlocks()
        record = {
            "time": int(self.time_alive),
            "kills": self.kills,
            "coins": earned,
            "level": self.player.level,
            "character": self.selected_character,
            "difficulty": self.difficulty,
            "won": won,
            "modifier": self.map_modifier,
            "synergies": list(self.active_synergies),
            "portal_kills": self.portal_kills,
            "events": self.replay_events[-5:],
        }
        self.progress.setdefault("history", []).insert(0, record)
        self.progress["history"] = self.progress["history"][:10]
        self.progress.setdefault("ranking", []).append(record)
        self.progress["ranking"] = sorted(self.progress["ranking"], key=lambda item: (item["time"], item["kills"], item["coins"]), reverse=True)[:10]
        for key in self.weapons:
            self.mark_codex("weapons", key)
        for key in self.relics:
            self.mark_codex("relics", key)
        self.save_progress()

    def calculate_progression_bonus(self, won):
        bonus = 0
        milestones = [
            (self.time_alive >= 120, 20, "Sobreviveu 2m +20"),
            (self.time_alive >= 300, 55, "Sobreviveu 5m +55"),
            (self.time_alive >= 600, 120, "Sobreviveu 10m +120"),
            (self.kills >= 100, 45, "100 KOs +45"),
            (self.kills >= 250, 90, "250 KOs +90"),
            (self.player.level >= 10, 60, "Nivel 10 +60"),
            (self.run_evolved >= 1, 85, "Arma evoluida +85"),
            (len(self.active_synergies) >= 1, 75, "Sinergia ativa +75"),
            (won, 150, "Meta concluida +150"),
        ]
        for condition, reward, label in milestones:
            if condition:
                bonus += reward
                self.run_unlocked.append(label)
        return bonus

    def apply_goal_reward(self, won):
        if not won:
            return
        minutes = self.win_time // 60
        key = f"goal_{minutes}"
        if key in self.progress.setdefault("goal_rewards", []):
            return
        reward = {10: 250, 15: 500, 30: 1200}.get(minutes, 150)
        self.progress["goal_rewards"].append(key)
        self.progress["coins"] += reward
        self.progress["total_coins"] += reward
        self.run_unlocked.append(f"Meta {minutes}m +{reward}")

    def apply_character_objective_reward(self):
        reward_key = f"character_{self.selected_character}"
        if reward_key in self.progress.setdefault("character_rewards", []):
            return
        complete = False
        if self.selected_character == "hunter":
            complete = self.kills >= 120
        elif self.selected_character == "knight":
            complete = self.run_boss_kills >= 1
        elif self.selected_character == "mage":
            complete = self.run_evolved >= 1
        elif self.selected_character == "rogue":
            complete = self.time_alive >= 300
        elif self.selected_character == "alchemist":
            complete = self.run_coins >= 300
        elif self.selected_character == "monk":
            complete = self.player.level >= 12
        if complete:
            reward = CHARACTER_OBJECTIVES[self.selected_character][1]
            self.progress["character_rewards"].append(reward_key)
            self.progress["coins"] += reward
            self.progress["total_coins"] += reward
            self.run_unlocked.append(f"Objetivo {CHARACTERS[self.selected_character][0]} +{reward}")

    def click_upgrade(self, pos):
        start_y = 170
        for i in range(3):
            rect = pygame.Rect(WIDTH / 2 - 260, start_y + i * 92, 520, 72)
            if rect.collidepoint(pos):
                self.pick_upgrade(i)

    def blit_asset(self, key, x, y, size):
        cache_key = (key, int(size))
        if cache_key not in self.scaled_cache:
            self.scaled_cache[cache_key] = pygame.transform.scale(self.assets[key], (int(size), int(size)))
        image = self.scaled_cache[cache_key]
        rect = image.get_rect(center=(x, y))
        self.screen.blit(image, rect)

    def draw_player(self):
        pos = self.screen_pos(self.player.x, self.player.y)
        bob = math.sin(self.time_alive * 10) * 3
        glow = pygame.Surface((76, 76), pygame.SRCALPHA)
        pygame.draw.circle(glow, (76, 148, 255, 42), (38, 38), 34)
        self.screen.blit(glow, (pos[0] - 38, pos[1] - 38))
        aim_end = (pos[0] + self.player.aim_dx * 31, pos[1] + self.player.aim_dy * 31)
        pygame.draw.line(self.screen, (180, 226, 255), pos, aim_end, 3)
        asset_key = f"player_{self.selected_character}"
        self.blit_asset(asset_key if asset_key in self.assets else "player", pos[0], pos[1] + bob, 58)
        if self.player.invuln > 0:
            pygame.draw.circle(self.screen, (230, 245, 255), pos, self.player.radius + 8, 2)

    def draw_crosshair(self):
        pos = self.screen_pos(self.player.aim_x, self.player.aim_y)
        dist = length(self.player.aim_x - self.player.x, self.player.aim_y - self.player.y)
        if dist < 18:
            pos = self.screen_pos(self.player.x + self.player.aim_dx * 72, self.player.y + self.player.aim_dy * 72)
        pulse = 1 + math.sin(self.time_alive * 12) * 0.08
        r = int(12 * pulse)
        pygame.draw.circle(self.screen, CYAN, pos, r, 2)
        pygame.draw.line(self.screen, CYAN, (pos[0] - r - 7, pos[1]), (pos[0] - r + 2, pos[1]), 2)
        pygame.draw.line(self.screen, CYAN, (pos[0] + r - 2, pos[1]), (pos[0] + r + 7, pos[1]), 2)
        pygame.draw.line(self.screen, CYAN, (pos[0], pos[1] - r - 7), (pos[0], pos[1] - r + 2), 2)
        pygame.draw.line(self.screen, CYAN, (pos[0], pos[1] + r - 2), (pos[0], pos[1] + r + 7), 2)

    def draw_enemy(self, enemy):
        pos = self.screen_pos(enemy.x, enemy.y)
        color = self.enemy_color(enemy)
        pulse = 1 + (0.06 * math.sin(self.time_alive * 7) if enemy.kind == "boss" else 0)
        asset_key = f"enemy_{enemy.kind}"
        shadow_rect = pygame.Rect(0, 0, enemy.radius * 2.4, enemy.radius * 0.7)
        shadow_rect.center = (pos[0], pos[1] + enemy.radius * 0.75)
        pygame.draw.ellipse(self.screen, (8, 10, 14, 130), shadow_rect)
        if enemy.windup > 0:
            progress = 1 - enemy.windup / max(0.01, enemy.windup_total)
            warning_color = ORANGE if enemy.kind == "exploder" else (PINK if enemy.kind == "archer" else self.enemy_color(enemy))
            if enemy.kind == "archer":
                target = self.screen_pos(enemy.target_x, enemy.target_y)
                pygame.draw.line(self.screen, warning_color, pos, target, 2)
                pygame.draw.circle(self.screen, warning_color, target, 8 + int(progress * 8), 2)
            elif enemy.kind == "exploder":
                radius = int(84 * (0.72 + progress * 0.28))
                pygame.draw.circle(self.screen, warning_color, pos, radius, 2)
                pygame.draw.circle(self.screen, GOLD, pos, enemy.radius + int(progress * 8), 2)
            elif enemy.kind == "summoner":
                radius = enemy.radius + 24 + int(progress * 18)
                pygame.draw.circle(self.screen, warning_color, pos, radius, 2)
                for i in range(6):
                    angle = math.tau * i / 6 + self.time_alive * 3
                    end = (pos[0] + math.cos(angle) * radius, pos[1] + math.sin(angle) * radius)
                    pygame.draw.line(self.screen, warning_color, pos, end, 1)
            elif enemy.kind in ("boss", "boss_warlock", "boss_frost", "miniboss"):
                radius = enemy.radius + 18 + int(progress * 28)
                pygame.draw.circle(self.screen, warning_color, pos, radius, 3)
                for i in range(8):
                    angle = math.tau * i / 8 + self.time_alive * 0.35
                    pygame.draw.line(self.screen, warning_color, pos, (pos[0] + math.cos(angle) * radius, pos[1] + math.sin(angle) * radius), 2)
        if asset_key in self.assets:
            self.blit_asset(asset_key, pos[0], pos[1] - 2, max(30, enemy.radius * 2.45 * pulse))
        elif enemy.kind == "runner":
            angle = math.atan2(self.player.y - enemy.y, self.player.x - enemy.x)
            points = []
            for offset, dist in ((0, enemy.radius * 1.25), (2.4, enemy.radius * 0.75), (math.pi, enemy.radius * 0.55), (-2.4, enemy.radius * 0.75)):
                points.append((pos[0] + math.cos(angle + offset) * dist, pos[1] + math.sin(angle + offset) * dist))
            pygame.draw.polygon(self.screen, color, points)
            pygame.draw.polygon(self.screen, (180, 255, 190), points, 2)
        elif enemy.kind == "archer":
            pygame.draw.circle(self.screen, color, pos, enemy.radius)
            pygame.draw.arc(self.screen, TEXT, (pos[0] - enemy.radius, pos[1] - enemy.radius, enemy.radius * 2, enemy.radius * 2), -1.1, 1.1, 2)
            pygame.draw.line(self.screen, TEXT, (pos[0] - enemy.radius, pos[1]), (pos[0] + enemy.radius, pos[1]), 2)
            pygame.draw.circle(self.screen, (255, 220, 235), (pos[0], pos[1] - 3), max(3, enemy.radius // 4))
        elif enemy.kind == "exploder":
            pygame.draw.circle(self.screen, (116, 48, 28), pos, enemy.radius)
            pygame.draw.circle(self.screen, ORANGE, pos, max(4, enemy.radius - 5), 2)
            pygame.draw.circle(self.screen, GOLD, pos, max(3, enemy.radius // 3))
            for i in range(6):
                angle = math.tau * i / 6 + self.time_alive * 2
                pygame.draw.line(self.screen, ORANGE, pos, (pos[0] + math.cos(angle) * enemy.radius, pos[1] + math.sin(angle) * enemy.radius), 1)
        elif enemy.kind == "summoner":
            diamond = [(pos[0], pos[1] - enemy.radius), (pos[0] + enemy.radius, pos[1]), (pos[0], pos[1] + enemy.radius), (pos[0] - enemy.radius, pos[1])]
            pygame.draw.polygon(self.screen, color, diamond)
            pygame.draw.polygon(self.screen, (230, 210, 255), diamond, 2)
            pygame.draw.circle(self.screen, (35, 18, 55), pos, max(4, enemy.radius // 2))
        elif enemy.kind.startswith("boss"):
            body_radius = int(enemy.radius * pulse)
            pygame.draw.circle(self.screen, (65, 18, 35), pos, body_radius + 6)
            pygame.draw.circle(self.screen, color, pos, body_radius)
            pygame.draw.circle(self.screen, (255, 210, 230), (pos[0] - 13, pos[1] - 8), 5)
            pygame.draw.circle(self.screen, (255, 210, 230), (pos[0] + 13, pos[1] - 8), 5)
            pygame.draw.polygon(self.screen, GOLD, [(pos[0] - 24, pos[1] - 34), (pos[0], pos[1] - 58), (pos[0] + 24, pos[1] - 34)])
            pygame.draw.line(self.screen, (255, 230, 140), (pos[0] - 30, pos[1] + 12), (pos[0] + 30, pos[1] + 12), 3)
        else:
            pygame.draw.circle(self.screen, (70, 25, 35), pos, enemy.radius + 3)
            pygame.draw.circle(self.screen, color, pos, enemy.radius)
            pygame.draw.circle(self.screen, (255, 190, 200), (pos[0] - 5, pos[1] - 5), max(2, enemy.radius // 5))
        if enemy.elite:
            pygame.draw.circle(self.screen, GOLD, pos, enemy.radius + 6, 2)
        if enemy.hit_flash > 0:
            flash = pygame.Surface((enemy.radius * 4, enemy.radius * 4), pygame.SRCALPHA)
            alpha = int(165 * enemy.hit_flash / 0.12)
            pygame.draw.circle(flash, (255, 255, 255, alpha), (flash.get_width() // 2, flash.get_height() // 2), enemy.radius + 5)
            self.screen.blit(flash, (pos[0] - flash.get_width() // 2, pos[1] - flash.get_height() // 2))
        if asset_key not in self.assets:
            eye_dx, eye_dy = norm(self.player.x - enemy.x, self.player.y - enemy.y)
            pygame.draw.circle(self.screen, (12, 13, 18), (pos[0] + eye_dx * 5, pos[1] + eye_dy * 5), max(3, enemy.radius // 4))

    def draw_projectile(self, projectile):
        pos = self.screen_pos(projectile.x, projectile.y)
        if projectile.kind == "enemy":
            if "projectile_enemy" in self.assets:
                self.blit_asset("projectile_enemy", pos[0], pos[1], projectile.radius * 3.2)
                return
            pygame.draw.circle(self.screen, RED, pos, projectile.radius)
            return
        if projectile.kind == "bomb":
            if "weapon_icon_bomb" in self.assets:
                self.blit_asset("weapon_icon_bomb", pos[0], pos[1], projectile.radius * 3.4)
                return
            pygame.draw.circle(self.screen, ORANGE, pos, projectile.radius + 5)
            pygame.draw.circle(self.screen, GOLD, pos, projectile.radius)
            return
        projectile_key = f"projectile_{projectile.source}"
        if projectile_key in self.assets:
            self.blit_asset(projectile_key, pos[0], pos[1], max(20, projectile.radius * 3))
            return
        icon_key = f"weapon_icon_{projectile.source}"
        if icon_key in self.assets and projectile.kind != "orbit":
            self.blit_asset(icon_key, pos[0], pos[1], max(22, projectile.radius * 3.2))
            return
        if projectile.source == "axe":
            pygame.draw.line(self.screen, GOLD, (pos[0] - 12, pos[1] - 8), (pos[0] + 12, pos[1] + 8), 5)
            pygame.draw.circle(self.screen, TEXT, pos, 5)
            return
        pygame.draw.circle(self.screen, projectile.color, pos, projectile.radius + 3)
        pygame.draw.circle(self.screen, TEXT, pos, max(2, projectile.radius - 2))

    def draw_effects(self):
        for effect in self.effects:
            age = 1 - effect.ttl / effect.duration
            alpha = max(0, int(180 * (1 - age)))
            pos = self.screen_pos(effect.x, effect.y)
            surf = pygame.Surface((int(effect.radius * 2.5), int(effect.radius * 2.5)), pygame.SRCALPHA)
            center = (surf.get_width() // 2, surf.get_height() // 2)
            radius = max(2, int(effect.radius * (0.25 + age)))
            color = (*effect.color, alpha)
            if effect.kind == "explosion":
                pygame.draw.circle(surf, color, center, radius, 5)
                pygame.draw.circle(surf, (*ORANGE, alpha // 2), center, max(2, radius // 2), 2)
            elif effect.kind == "shockwave":
                pygame.draw.circle(surf, color, center, radius, 3)
                pygame.draw.circle(surf, (*TEXT, alpha // 3), center, max(2, radius // 2), 1)
            elif effect.kind == "hit":
                pygame.draw.circle(surf, (*TEXT, alpha), center, max(3, radius // 3), 2)
                for i in range(6):
                    angle = math.tau * i / 6 + age * 2
                    start = (center[0] + math.cos(angle) * radius * 0.25, center[1] + math.sin(angle) * radius * 0.25)
                    end = (center[0] + math.cos(angle) * radius, center[1] + math.sin(angle) * radius)
                    pygame.draw.line(surf, color, start, end, 2)
            elif effect.kind == "pickup":
                for i in range(4):
                    angle = math.tau * i / 4 + age * 2
                    p1 = (center[0] + math.cos(angle) * radius * 0.2, center[1] + math.sin(angle) * radius * 0.2)
                    p2 = (center[0] + math.cos(angle) * radius, center[1] + math.sin(angle) * radius)
                    pygame.draw.line(surf, color, p1, p2, 2)
                pygame.draw.circle(surf, color, center, max(2, radius // 4), 2)
            elif effect.kind == "level":
                pygame.draw.circle(surf, color, center, radius, 3)
                for i in range(12):
                    angle = math.tau * i / 12 - age * 3
                    end = (center[0] + math.cos(angle) * radius, center[1] + math.sin(angle) * radius)
                    pygame.draw.line(surf, color, center, end, 2)
            elif effect.kind == "evolve":
                for i in range(9):
                    angle = math.tau * i / 9 + age * 4
                    end = (center[0] + math.cos(angle) * radius, center[1] + math.sin(angle) * radius)
                    pygame.draw.line(surf, color, center, end, 3)
                pygame.draw.circle(surf, color, center, radius, 3)
            elif effect.kind == "legendary":
                points = []
                for i in range(10):
                    r = radius if i % 2 == 0 else radius * 0.48
                    angle = math.tau * i / 10 - math.pi / 2 + age * 2
                    points.append((center[0] + math.cos(angle) * r, center[1] + math.sin(angle) * r))
                pygame.draw.polygon(surf, color, points, 3)
            elif effect.kind == "bolt":
                for _ in range(4):
                    pygame.draw.line(surf, color, (random.randint(10, surf.get_width() - 10), 0), (random.randint(10, surf.get_width() - 10), surf.get_height()), 2)
            elif effect.kind == "death":
                for i in range(8):
                    angle = math.tau * i / 8 + age * 1.5
                    end = (center[0] + math.cos(angle) * radius, center[1] + math.sin(angle) * radius)
                    pygame.draw.line(surf, color, center, end, 3)
                pygame.draw.circle(surf, color, center, max(3, radius // 2), 2)
            else:
                pygame.draw.circle(surf, color, center, radius, 3)
            self.screen.blit(surf, (pos[0] - center[0], pos[1] - center[1]))

    def draw_vignette(self):
        vignette = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        pygame.draw.rect(vignette, (0, 0, 0, 80), (0, 0, WIDTH, HEIGHT), 26)
        pygame.draw.rect(vignette, (0, 0, 0, 0), (42, 42, WIDTH - 84, HEIGHT - 84), border_radius=18)
        self.screen.blit(vignette, (0, 0))

    def draw_world(self):
        base_x, base_y = self.camera()
        shake_x = random.uniform(-self.shake, self.shake) if self.shake > 0 else 0
        shake_y = random.uniform(-self.shake, self.shake) if self.shake > 0 else 0
        cam_x = clamp(base_x + shake_x, 0, WORLD_W - WIDTH)
        cam_y = clamp(base_y + shake_y, 0, WORLD_H - HEIGHT)
        self.render_cam = (cam_x, cam_y)
        self.screen.fill((8, 10, 15) if self.event_name == "Neblina" and self.event_time > 0 else BG)
        self.draw_tilemap(cam_x, cam_y)
        self.draw_map_landmarks()

        for detail in self.terrain_details:
            self.draw_terrain_detail(detail)

        pygame.draw.rect(self.screen, (37, 43, 58), pygame.Rect(-cam_x, -cam_y, WORLD_W, WORLD_H), 4)

        for obstacle in self.obstacles:
            pos = self.screen_pos(obstacle.x, obstacle.y)
            if -60 < pos[0] < WIDTH + 60 and -60 < pos[1] < HEIGHT + 60:
                asset_key = obstacle.kind if obstacle.kind in self.assets else "stone"
                size = obstacle.radius * 2.2
                if asset_key == "tree":
                    size = obstacle.radius * 4.0
                    self.blit_asset(asset_key, pos[0], pos[1] - obstacle.radius * 0.75, size)
                else:
                    self.blit_asset(asset_key, pos[0], pos[1], size)

        for altar in self.altars:
            pos = self.screen_pos(altar.x, altar.y)
            color = GOLD if altar.active else (70, 66, 58)
            pygame.draw.circle(self.screen, (20, 18, 14), pos, altar.radius + 8)
            altar_key = f"altar_{altar.kind}"
            if altar_key in self.assets or "altar" in self.assets:
                self.blit_asset(altar_key if altar_key in self.assets else "altar", pos[0], pos[1], altar.radius * 2.35)
                if altar.active:
                    pygame.draw.circle(self.screen, color, pos, altar.radius + 5, 2)
            else:
                pygame.draw.circle(self.screen, color, pos, altar.radius, 3)
                pygame.draw.circle(self.screen, color, pos, 5 if altar.active else 3)

        for merchant in self.merchants:
            if merchant.active:
                pos = self.screen_pos(merchant.x, merchant.y)
                pygame.draw.circle(self.screen, (30, 22, 12), pos, merchant.radius + 8)
                pygame.draw.circle(self.screen, GOLD, pos, merchant.radius)
                pygame.draw.rect(self.screen, (75, 40, 18), (pos[0] - 16, pos[1] + 5, 32, 18), border_radius=4)

        for portal in self.portals:
            if portal.active:
                pos = self.screen_pos(portal.x, portal.y)
                radius = portal.radius + int(math.sin(self.time_alive * 7) * 4)
                if "portal" in self.assets:
                    pygame.draw.circle(self.screen, VIOLET, pos, radius + 4, 3)
                    self.blit_asset("portal", pos[0], pos[1], radius * 2.1)
                else:
                    pygame.draw.circle(self.screen, VIOLET, pos, radius, 4)
                    pygame.draw.circle(self.screen, CYAN, pos, max(4, radius // 2), 2)

        for item in self.breakables:
            pos = self.screen_pos(item.x, item.y)
            if -40 < pos[0] < WIDTH + 40 and -40 < pos[1] < HEIGHT + 40:
                self.blit_asset("crate", pos[0], pos[1], item.radius * 2.4)

        for chest in self.chests:
            pos = self.screen_pos(chest.x, chest.y)
            self.blit_asset("chest", pos[0], pos[1], 42)

        for gem in self.gems:
            pos = self.screen_pos(gem.x, gem.y)
            self.blit_asset("gem", pos[0], pos[1] + math.sin(self.time_alive * 8 + gem.x) * 2, 24)

        for projectile in self.projectiles:
            self.draw_projectile(projectile)
        self.draw_effects()

        for enemy in self.enemies:
            self.draw_enemy(enemy)

        for particle in self.particles:
            pygame.draw.circle(self.screen, particle.color, self.screen_pos(particle.x, particle.y), max(1, int(particle.radius * max(0.2, particle.ttl * 4))))

        for pet in self.pets:
            pos = self.screen_pos(pet.x, pet.y)
            pygame.draw.circle(self.screen, (15, 28, 20), pos, 13)
            pygame.draw.circle(self.screen, GREEN, pos, 9)
            pygame.draw.circle(self.screen, TEXT, (pos[0] - 3, pos[1] - 2), 2)

        self.draw_player()
        self.draw_crosshair()

        if self.event_name == "Neblina" and self.event_time > 0:
            fog = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            fog.fill((160, 170, 185, 45))
            self.screen.blit(fog, (0, 0))
        self.draw_vignette()

        if self.flash > 0:
            flash = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            flash.fill((255, 230, 210, int(80 * self.flash)))
            self.screen.blit(flash, (0, 0))

    def enemy_color(self, enemy):
        return {
            "shade": RED,
            "runner": GREEN,
            "brute": GOLD,
            "archer": PINK,
            "exploder": ORANGE,
            "summoner": VIOLET,
            "boss": (255, 68, 102),
            "boss_warlock": VIOLET,
            "boss_frost": CYAN,
            "miniboss": (255, 120, 80),
        }[enemy.kind]

    def draw_hud(self):
        self.draw_panel(pygame.Rect(18, 16, 318, 92), (15, 20, 30), (54, 65, 83))
        draw_text(self.screen, self.small_font, f"Nivel {self.player.level}", (34, 20), TEXT)
        draw_text(self.screen, self.small_font, f"HP {int(self.player.hp)}/{int(self.player.max_hp)}", (226, 20), MUTED)
        self.draw_bar(pygame.Rect(34, 42, 260, 13), self.player.hp, self.player.max_hp, RED, "")
        self.draw_bar(pygame.Rect(34, 70, 260, 11), self.player.xp, self.player.xp_to_level, CYAN, "")
        draw_text(self.screen, self.small_font, f"XP {self.player.xp}/{self.player.xp_to_level}", (34, 84), MUTED)

        seconds = int(self.time_alive)
        timer = f"{seconds // 60:02d}:{seconds % 60:02d}"
        self.draw_panel(pygame.Rect(WIDTH / 2 - 86, 16, 172, 72), (15, 20, 30), (54, 65, 83))
        draw_text(self.screen, self.font, timer, (WIDTH // 2, 25), TEXT, center=True)
        draw_text(self.screen, self.small_font, f"Meta {self.win_time // 60}m", (WIDTH // 2, 52), MUTED, center=True)
        draw_text(self.screen, self.small_font, self.map_modifier_text, (WIDTH // 2, 72), GOLD, center=True)
        self.draw_panel(pygame.Rect(WIDTH - 306, 16, 288, 34), (15, 20, 30), (54, 65, 83))
        draw_text(self.screen, self.small_font, f"Onda {self.wave}   KOs {self.kills}   Pontos {self.score}", (WIDTH - 290, 25), MUTED)
        draw_text(self.screen, self.small_font, "Armas: " + ", ".join(WEAPON_INFO[k][0] + ("*" if w.evolved else f" {w.level}") for k, w in self.weapons.items()), (18, HEIGHT - 28), MUTED)
        if self.active_synergies:
            draw_text(self.screen, self.small_font, "Sinergias: " + ", ".join(SYNERGIES[k][0] for k in self.active_synergies), (18, HEIGHT - 76), CYAN)
        if self.portal_timer > 0:
            draw_text(self.screen, self.small_font, f"Arena especial: {int(self.portal_timer)}s KOs {self.portal_kills}/18", (WIDTH / 2, 92), VIOLET, center=True)

        progress_text = self.event_progress_text()
        if self.event_time > 0:
            draw_text(self.screen, self.font, self.event_name, (WIDTH / 2, 104), RARITIES["lendario"]["color"], center=True)
        if progress_text:
            draw_text(self.screen, self.small_font, progress_text, (WIDTH / 2, 128), GOLD, center=True)
        elif self.event_warning_time > 0 and self.pending_event:
            warning_color = ORANGE if int(self.event_warning_time * 4) % 2 == 0 else GOLD
            draw_text(self.screen, self.font, f"Prepare-se: {self.pending_event}", (WIDTH / 2, 112), warning_color, center=True)
        if self.story_time > 0:
            story_y = 150 if self.event_time > 0 else 118
            draw_text(self.screen, self.small_font, self.story_text, (WIDTH / 2, story_y), TEXT, center=True)
        music_label = "Chefe" if self.current_music == "boss" else "Floresta"
        draw_text(self.screen, self.small_font, f"Trilha: {music_label}", (WIDTH - 150, 184), MUTED, center=True)

        for x, y, text, _ttl, color in self.floating_text:
            draw_text(self.screen, self.small_font, text, self.screen_pos(x, y), color, center=True)

        if self.joystick_origin and self.joystick_pos:
            pygame.draw.circle(self.screen, (48, 56, 72), self.joystick_origin, 45, 3)
            pygame.draw.circle(self.screen, CYAN, self.joystick_pos, 18)

        self.draw_minimap()

    def draw_minimap(self):
        w, h = 172, 122
        x, y = WIDTH - w - 18, 52
        pygame.draw.rect(self.screen, (9, 12, 18), (x, y, w, h), border_radius=6)
        pygame.draw.rect(self.screen, (70, 78, 96), (x, y, w, h), 2, border_radius=6)

        pygame.draw.rect(self.screen, (54, 132, 62), (x + 2, y + 2, w - 4, h - 4))

        for landmark in getattr(self, "map_landmarks", []):
            lx = x + landmark["x"] / WORLD_W * w
            ly = y + landmark["y"] / WORLD_H * h
            if landmark["kind"] == "lake":
                pygame.draw.ellipse(self.screen, (58, 146, 156), (lx - 8, ly - 4, 16, 8))
            elif landmark["kind"] == "ruin":
                pygame.draw.rect(self.screen, (150, 155, 134), (lx - 4, ly - 4, 8, 8), 1)
            elif landmark["kind"] == "boss_clearing":
                pygame.draw.circle(self.screen, ORANGE, (lx, ly), 4, 1)

        for obstacle in self.obstacles[::3]:
            ox = x + obstacle.x / WORLD_W * w
            oy = y + obstacle.y / WORLD_H * h
            pygame.draw.circle(self.screen, (97, 106, 96), (ox, oy), 1)
        for altar in self.altars:
            ax = x + altar.x / WORLD_W * w
            ay = y + altar.y / WORLD_H * h
            pygame.draw.circle(self.screen, GOLD if altar.active else MUTED, (ax, ay), 3)
        for chest in self.chests:
            cx = x + chest.x / WORLD_W * w
            cy = y + chest.y / WORLD_H * h
            pygame.draw.rect(self.screen, GOLD, (cx - 2, cy - 2, 4, 4))
        for merchant in self.merchants:
            if merchant.active:
                mx = x + merchant.x / WORLD_W * w
                my = y + merchant.y / WORLD_H * h
                pygame.draw.circle(self.screen, GOLD, (mx, my), 3)
        for portal in self.portals:
            if portal.active:
                px2 = x + portal.x / WORLD_W * w
                py2 = y + portal.y / WORLD_H * h
                pygame.draw.circle(self.screen, VIOLET, (px2, py2), 3)
        for enemy in self.enemies[:: max(1, len(self.enemies) // 35 or 1)]:
            ex = x + enemy.x / WORLD_W * w
            ey = y + enemy.y / WORLD_H * h
            pygame.draw.circle(self.screen, RED if enemy.kind != "boss" else PINK, (ex, ey), 2)

        px = x + self.player.x / WORLD_W * w
        py = y + self.player.y / WORLD_H * h
        pygame.draw.circle(self.screen, CYAN, (px, py), 4)
        if self.relics:
            draw_text(self.screen, self.small_font, "Reliquias: " + ", ".join(RELIC_INFO[k][0] for k in self.relics), (18, HEIGHT - 52), GOLD)

    def draw_progress_shell(self, title):
        self.screen.fill((11, 13, 20))
        for i in range(36):
            x = (i * 83 + int(self.time_alive * 8)) % WIDTH
            y = (i * 47) % HEIGHT
            pygame.draw.circle(self.screen, (22, 27, 38), (x, y), 2)
        pygame.draw.rect(self.screen, (15, 19, 29), (0, 0, WIDTH, 112))
        pygame.draw.line(self.screen, (48, 59, 78), (0, 112), (WIDTH, 112), 2)
        draw_text(self.screen, self.big_font, title, (WIDTH / 2, 56), TEXT, center=True)
        self.draw_panel(pygame.Rect(24, 22, 185, 74), (18, 23, 34), (55, 66, 86))
        draw_text(self.screen, self.font, f"Moedas: {self.progress['coins']}", (38, 30), GOLD)
        char_name = CHARACTERS[self.selected_character][0]
        draw_text(self.screen, self.small_font, f"Personagem: {char_name}", (38, 60), MUTED)
        objective = CHARACTER_OBJECTIVES.get(self.selected_character)
        if objective:
            draw_text(self.screen, self.small_font, f"Objetivo: {objective[0]}", (WIDTH / 2, 92), MUTED, center=True)

    def draw_menu(self):
        self.set_music("menu")
        self.draw_progress_shell("Noite dos Sobreviventes")
        moon_x = WIDTH / 2
        moon_y = 140
        pygame.draw.circle(self.screen, (235, 225, 188), (moon_x, moon_y), 24)
        pygame.draw.circle(self.screen, (11, 13, 20), (moon_x + 10, moon_y - 4), 22)
        for i in range(12):
            angle = math.tau * i / 12 + self.time_alive * 0.4
            pygame.draw.circle(self.screen, (55, 68, 92), (moon_x + math.cos(angle) * 52, moon_y + math.sin(angle) * 30), 2)
        menu_items = [
            "Iniciar partida",
            "Loja permanente",
            "Personagens",
            "Conquistas e desbloqueios",
            "Talentos",
            "Prestigio",
            "Codex",
            "Ranking e historico",
            "Slots de save",
            f"Dificuldade: {DIFFICULTIES[self.difficulty][0]}",
        ]
        for i, item in enumerate(menu_items):
            rect = pygame.Rect(WIDTH / 2 - 190, 184 + i * 27, 380, 24)
            selected = self.nav_index() == i
            pygame.draw.rect(self.screen, (26, 31, 43), rect, border_radius=6)
            pygame.draw.rect(self.screen, CYAN if selected else (68, 76, 94), rect, 2, border_radius=6)
            if selected:
                pygame.draw.circle(self.screen, CYAN, (rect.x - 14, rect.centery), 5)
            draw_text(self.screen, self.small_font, item, rect.center, CYAN if selected else TEXT, center=True)
        best = self.progress["best_time"]
        diff_name = DIFFICULTIES[self.difficulty][0]
        draw_text(self.screen, self.small_font, f"Setas navegam | ENTER confirma | Slot {self.save_slot} | Dificuldade {diff_name} | Melhor {best // 60:02d}:{best % 60:02d} | Prestigio {self.progress['prestige']} | Pontos {self.progress['prestige_points']}", (WIDTH / 2, 482), MUTED, center=True)
        unlocked = ", ".join(WEAPON_INFO[k][0] for k in self.progress["unlocked_weapons"])
        draw_text(self.screen, self.small_font, f"Armas liberadas: {unlocked}", (WIDTH / 2, 510), MUTED, center=True)

    def draw_options(self):
        self.draw_progress_shell("Opcoes")
        muted = "Sim" if self.progress.get("muted", False) else "Nao"
        items = [
            f"Mudo: {muted}",
            f"Musica: < {int(self.progress.get('music_volume', 0.18) * 100)}% >",
            f"Efeitos: < {int(self.progress.get('sfx_volume', 0.8) * 100)}% >",
            "Voltar",
        ]
        for i, item in enumerate(items):
            rect = pygame.Rect(WIDTH / 2 - 215, 158 + i * 64, 430, 48)
            self.draw_button(rect, item, i, GOLD if i in (1, 2) else TEXT)
        draw_text(self.screen, self.small_font, "Setas navegam | esquerda/direita ajustam | ENTER confirma | ESC volta", (WIDTH / 2, HEIGHT - 42), MUTED, center=True)

    def draw_tutorial(self):
        self.draw_progress_shell("Tutorial")
        lines = [
            "Mova com WASD ou setas. As armas atacam automaticamente.",
            "Pegue gemas azuis para subir de nivel e escolher upgrades.",
            "Chefes deixam baus. Altares no mapa ativam efeitos fortes.",
            "R na tela de upgrade troca as opcoes. B bane a primeira opcao.",
            "P pausa. Se a janela perder foco, o jogo pausa sozinho.",
            "Sobreviva ate a meta ou continue no modo infinito depois da vitoria.",
        ]
        for i, line in enumerate(lines):
            draw_text(self.screen, self.font, line, (WIDTH / 2, 145 + i * 48), TEXT if i == 0 else MUTED, center=True)
        self.draw_nav_text("Voltar ao menu", (WIDTH / 2, HEIGHT - 42), 0, CYAN, center=True, font=self.small_font)

    def draw_shop(self):
        self.draw_progress_shell("Loja Permanente")
        y = 122
        for i, key in enumerate(PERMANENT_UPGRADES):
            name, desc, base_cost = PERMANENT_UPGRADES[key]
            level = self.progress["permanent_upgrades"].get(key, 0)
            cost = base_cost + level * base_cost // 2
            color = MUTED if level >= 10 else (GOLD if self.progress["coins"] >= cost else RED)
            rect = pygame.Rect(150, y + i * 45, 660, 38)
            self.draw_nav_rect(rect, i, color)
            price = "MAX" if level >= 10 else f"{cost} moedas"
            draw_text(self.screen, self.small_font, f"{i + 1}. {name} Nv.{level}", (rect.x + 18, rect.y + 5), TEXT)
            draw_text(self.screen, self.small_font, desc, (rect.x + 210, rect.y + 5), MUTED)
            draw_text(self.screen, self.small_font, price, (rect.right - 125, rect.y + 5), color)
        self.draw_button(pygame.Rect(WIDTH / 2 - 120, HEIGHT - 62, 240, 38), "Voltar", len(PERMANENT_UPGRADES), MUTED, self.small_font)

    def draw_talents(self):
        self.draw_progress_shell("Arvore de Talentos")
        draw_text(self.screen, self.font, f"Pontos de prestigio: {self.progress['prestige_points']}", (WIDTH / 2, 118), GOLD, center=True)
        for i, key in enumerate(TALENTS):
            name, desc, base_cost = TALENTS[key]
            level = self.progress["talents"].get(key, 0)
            cost = base_cost + level
            rect = pygame.Rect(150, 146 + i * 48, 660, 40)
            color = MUTED if level >= 6 else (GOLD if self.progress["prestige_points"] >= cost else RED)
            self.draw_nav_rect(rect, i, color)
            price = "MAX" if level >= 6 else f"{cost} pts"
            draw_text(self.screen, self.small_font, f"{i + 1}. {name} Nv.{level}", (rect.x + 18, rect.y + 7), TEXT)
            draw_text(self.screen, self.small_font, desc, (rect.x + 210, rect.y + 7), MUTED)
            draw_text(self.screen, self.small_font, price, (rect.right - 75, rect.y + 7), color)
        self.draw_button(pygame.Rect(WIDTH / 2 - 120, HEIGHT - 62, 240, 38), "Voltar", len(TALENTS), MUTED, self.small_font)

    def draw_prestige(self):
        self.draw_progress_shell("Prestigio")
        gained = max(1, self.progress.get("best_time", 0) // 300 + self.progress.get("total_kills", 0) // 500)
        ready = self.progress.get("best_time", 0) >= 600 or self.progress.get("total_kills", 0) >= 1000
        color = GOLD if ready else MUTED
        lines = [
            f"Prestigio atual: {self.progress['prestige']}",
            f"Pontos atuais: {self.progress['prestige_points']}",
            f"Proximo prestigio concede: {gained} pontos",
            "Reinicia moedas, loja, desbloqueios e estatisticas globais.",
            "Mantem talentos, codex, ranking e historico.",
            "Requer melhor tempo 10m ou 1000 KOs totais.",
        ]
        for i, line in enumerate(lines):
            draw_text(self.screen, self.font, line, (WIDTH / 2, 150 + i * 48), color if i == 2 else TEXT, center=True)
        self.draw_nav_text("Confirmar prestigio", (WIDTH / 2, HEIGHT - 88), 0, CYAN if ready else MUTED, center=True)
        self.draw_nav_text("Voltar", (WIDTH / 2, HEIGHT - 48), 1, MUTED, center=True, font=self.small_font)

    def draw_codex(self):
        self.draw_progress_shell("Codex")
        seen = self.progress.get("codex_seen", {})
        columns = [
            ("Inimigos", seen.get("enemies", [])),
            ("Armas", seen.get("weapons", [])),
            ("Reliquias", seen.get("relics", [])),
        ]
        for ci, (title, items) in enumerate(columns):
            x = 80 + ci * 300
            draw_text(self.screen, self.font, title, (x, 130), GOLD)
            if not items:
                draw_text(self.screen, self.small_font, "Nada visto ainda", (x, 166), MUTED)
            for i, key in enumerate(items[:12]):
                if title == "Armas":
                    label = WEAPON_INFO.get(key, (key,))[0]
                elif title == "Reliquias":
                    label = RELIC_INFO.get(key, (key,))[0]
                else:
                    label = key
                draw_text(self.screen, self.small_font, f"- {label}", (x, 166 + i * 25), TEXT)
        self.draw_nav_text("Voltar", (WIDTH / 2, HEIGHT - 42), 0, MUTED, center=True, font=self.small_font)

    def draw_records(self):
        self.draw_progress_shell("Ranking e Historico")
        draw_text(self.screen, self.font, "Ranking local", (130, 125), GOLD)
        for i, rec in enumerate(self.progress.get("ranking", [])[:7]):
            text = f"{i + 1}. {rec['time']//60:02d}:{rec['time']%60:02d}  KOs {rec['kills']}  Moedas {rec['coins']}  {rec['character']}"
            draw_text(self.screen, self.small_font, text, (110, 164 + i * 30), TEXT)
        draw_text(self.screen, self.font, "Ultimas partidas", (560, 125), GOLD)
        for i, rec in enumerate(self.progress.get("history", [])[:7]):
            status = "V" if rec.get("won") else "D"
            text = f"{status} {rec['time']//60:02d}:{rec['time']%60:02d}  Nv {rec['level']}  {rec['difficulty']}"
            draw_text(self.screen, self.small_font, text, (550, 164 + i * 30), TEXT)
        self.draw_nav_text("Voltar", (WIDTH / 2, HEIGHT - 42), 0, MUTED, center=True, font=self.small_font)

    def draw_slots(self):
        self.draw_progress_shell("Slots de Save")
        for i, path in enumerate(SAVE_SLOT_FILES):
            exists = os.path.exists(path)
            label = f"Slot {i + 1}"
            if exists:
                try:
                    with open(path, "r", encoding="utf-8") as file:
                        data = json.load(file)
                    label += f" - moedas {data.get('coins', 0)} - melhor {data.get('best_time', 0)//60:02d}:{data.get('best_time', 0)%60:02d}"
                except (OSError, json.JSONDecodeError):
                    label += " - corrompido"
            else:
                label += " - vazio"
            color = CYAN if self.save_slot == i + 1 else TEXT
            rect = pygame.Rect(WIDTH / 2 - 260, 160 + i * 70, 520, 50)
            self.draw_button(rect, f"{i + 1}. {label}", i, color)
        self.draw_button(pygame.Rect(WIDTH / 2 - 120, HEIGHT - 62, 240, 38), "Voltar", len(SAVE_SLOT_FILES), MUTED, self.small_font)

    def draw_characters(self):
        self.draw_progress_shell("Personagens")
        for i, key in enumerate(CHARACTERS):
            name, desc, stats = CHARACTERS[key]
            unlocked = key in self.progress.get("unlocked_characters", [])
            color = CYAN if key == self.selected_character else (TEXT if unlocked else MUTED)
            col = i % 3
            row = i // 3
            rect = pygame.Rect(145 + col * 230, 126 + row * 178, 190, 156)
            self.draw_nav_rect(rect, i, color)
            pygame.draw.circle(self.screen, color, (rect.centerx, rect.y + 42), 22)
            draw_text(self.screen, self.font, f"{i + 1}. {name}", (rect.centerx, rect.y + 72), color, center=True)
            draw_text(self.screen, self.small_font, desc, (rect.centerx, rect.y + 102), MUTED, center=True)
            status = "Selecionado" if key == self.selected_character else ("Disponivel" if unlocked else "Bloqueado")
            draw_text(self.screen, self.small_font, status, (rect.centerx, rect.y + 130), color, center=True)
        self.draw_nav_text("Voltar", (WIDTH / 2, HEIGHT - 52), len(CHARACTERS), MUTED, center=True, font=self.small_font)
        draw_text(self.screen, self.small_font, "Novos: Ladina 400 KOs | Alquimista 3 chefes | Monge vencer 10m", (WIDTH / 2, HEIGHT - 26), MUTED, center=True)

    def draw_achievements(self):
        self.draw_progress_shell("Conquistas")
        y = 130
        for i, key in enumerate(ACHIEVEMENTS):
            name, desc, reward = ACHIEVEMENTS[key]
            done = key in self.progress["achievements"]
            color = GOLD if done else MUTED
            row_y = y + i * 54
            pygame.draw.rect(self.screen, (24, 29, 41), (170, row_y, 620, 42), border_radius=6)
            draw_text(self.screen, self.font, ("OK " if done else "-- ") + name, (190, row_y + 8), color)
            draw_text(self.screen, self.small_font, f"{desc} | recompensa {reward}", (450, row_y + 13), MUTED)
        self.draw_nav_text("Voltar", (WIDTH / 2, HEIGHT - 42), 0, MUTED, center=True, font=self.small_font)

    def draw_pause(self):
        overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        overlay.fill((5, 7, 12, 205))
        self.screen.blit(overlay, (0, 0))
        modal = pygame.Rect(WIDTH / 2 - 210, 128, 420, 268)
        self.draw_panel(modal, (17, 22, 34), (72, 84, 108))
        draw_text(self.screen, self.big_font, "Pausado", (WIDTH / 2, 176), TEXT, center=True)
        self.draw_button(pygame.Rect(WIDTH / 2 - 150, 226, 300, 42), "Continuar", 0, CYAN)
        self.draw_button(pygame.Rect(WIDTH / 2 - 150, 278, 300, 42), "Reiniciar partida", 1, TEXT)
        self.draw_button(pygame.Rect(WIDTH / 2 - 150, 330, 300, 42), "Salvar e voltar ao menu", 2, TEXT)

    def upgrade_icon_key(self, kind, key):
        if kind.startswith("weapon"):
            return f"weapon_icon_{key}"
        if kind == "passive":
            return f"passive_icon_{key}"
        if kind == "relic":
            return f"relic_icon_{key}"
        return ""

    def draw_upgrade(self):
        overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        overlay.fill((5, 7, 12, 190))
        self.screen.blit(overlay, (0, 0))
        title = "Bau especial" if self.state == "chest" else "Escolha um upgrade"
        draw_text(self.screen, self.big_font, title, (WIDTH / 2, 92), TEXT, center=True)
        draw_text(self.screen, self.small_font, "1, 2, 3 ou clique em uma opcao", (WIDTH / 2, 132), MUTED, center=True)
        start_y = 170
        for i, (_kind, _key, name, desc, rarity) in enumerate(self.upgrade_choices):
            rect = pygame.Rect(WIDTH / 2 - 260, start_y + i * 92, 520, 72)
            color = RARITIES[rarity]["color"]
            if rarity == "lendario":
                shimmer = int(30 + 30 * math.sin(self.time_alive * 8 + i))
                pygame.draw.rect(self.screen, (shimmer, shimmer, 10), rect.inflate(10, 10), border_radius=10)
            pygame.draw.rect(self.screen, (34, 41, 56), rect, border_radius=8)
            pygame.draw.rect(self.screen, color, rect, 2, border_radius=8)
            icon_key = self.upgrade_icon_key(_kind, _key)
            text_x = rect.x + 22
            if icon_key in self.assets:
                icon_rect = pygame.Rect(rect.x + 14, rect.y + 13, 46, 46)
                pygame.draw.rect(self.screen, (18, 22, 31), icon_rect, border_radius=6)
                self.blit_asset(icon_key, icon_rect.centerx, icon_rect.centery, 38)
                text_x = rect.x + 72
            draw_text(self.screen, self.font, f"{i + 1}. {name}", (text_x, rect.y + 10), TEXT)
            draw_text(self.screen, self.small_font, f"{rarity.upper()} - {desc}", (text_x, rect.y + 43), color)
        draw_text(self.screen, self.small_font, f"R reroll ({self.rerolls}) | B banir primeira opcao ({self.banishes})", (WIDTH / 2, 468), MUTED, center=True)
        evolvable = [WEAPON_INFO[k][0] for k, w in self.weapons.items() if w.level >= 8 and not w.evolved]
        if evolvable:
            draw_text(self.screen, self.small_font, "Pode evoluir: " + ", ".join(evolvable), (WIDTH / 2, 496), GOLD, center=True)

    def draw_game_over(self):
        overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        overlay.fill((5, 7, 12, 210))
        self.screen.blit(overlay, (0, 0))
        title = "Vitoria" if self.state == "victory" else "Fim da noite"
        draw_text(self.screen, self.big_font, title, (WIDTH / 2, 170), TEXT, center=True)
        draw_text(self.screen, self.font, f"Sobreviveu {int(self.time_alive)}s | Nivel {self.player.level} | KOs {self.kills} | Moedas +{self.run_coins}", (WIDTH / 2, 242), MUTED, center=True)
        top_damage = sorted(self.damage_by_weapon.items(), key=lambda item: item[1], reverse=True)[:3]
        damage_line = "Dano: " + " | ".join(f"{WEAPON_INFO.get(k, ('Outros',))[0]} {v}" for k, v in top_damage if v > 0)
        draw_text(self.screen, self.small_font, damage_line, (WIDTH / 2, 276), MUTED, center=True)
        if self.state == "victory":
            draw_text(self.screen, self.font, "I modo infinito | R nova partida | M menu", (WIDTH / 2, 330), CYAN, center=True)
        else:
            draw_text(self.screen, self.font, "R nova partida | M menu", (WIDTH / 2, 330), CYAN, center=True)
        if self.run_unlocked:
            draw_text(self.screen, self.font, "Novidades liberadas", (WIDTH / 2, 386), GOLD, center=True)
            draw_text(self.screen, self.small_font, " | ".join(self.run_unlocked[:6]), (WIDTH / 2, 420), TEXT, center=True)
        replay = f"Replay: mod {MAP_MODIFIERS[self.map_modifier][0]} | portal KOs {self.portal_kills} | sinergias {len(self.active_synergies)}"
        draw_text(self.screen, self.small_font, replay, (WIDTH / 2, 456), MUTED, center=True)
        if self.replay_events:
            last_time, last_event = self.replay_events[-1]
            draw_text(self.screen, self.small_font, f"Ultimo evento {last_time}s: {last_event}", (WIDTH / 2, 482), MUTED, center=True)

    def draw_title_hint(self):
        if self.time_alive < 6 and self.state == "playing":
            draw_text(self.screen, self.small_font, "WASD/setas para mover. F1/F2/F3 escolhe meta 10/15/30m nos primeiros segundos.", (WIDTH / 2, HEIGHT - 54), MUTED, center=True)

    async def run(self):
        running = True
        while running:
            dt = min(self.clock.tick(FPS) / 1000, 0.033)
            running = self.handle_events()
            self.time_alive += dt if self.state in ("menu", "shop", "characters", "achievements", "options", "tutorial") else 0
            if self.state == "menu":
                self.draw_menu()
                pygame.display.flip()
                await asyncio.sleep(0)
                continue
            if self.state == "options":
                self.draw_options()
                pygame.display.flip()
                await asyncio.sleep(0)
                continue
            if self.state == "tutorial":
                self.draw_tutorial()
                pygame.display.flip()
                await asyncio.sleep(0)
                continue
            if self.state == "shop":
                self.draw_shop()
                pygame.display.flip()
                await asyncio.sleep(0)
                continue
            if self.state == "talents":
                self.draw_talents()
                pygame.display.flip()
                await asyncio.sleep(0)
                continue
            if self.state == "prestige":
                self.draw_prestige()
                pygame.display.flip()
                await asyncio.sleep(0)
                continue
            if self.state == "codex":
                self.draw_codex()
                pygame.display.flip()
                await asyncio.sleep(0)
                continue
            if self.state == "records":
                self.draw_records()
                pygame.display.flip()
                await asyncio.sleep(0)
                continue
            if self.state == "slots":
                self.draw_slots()
                pygame.display.flip()
                await asyncio.sleep(0)
                continue
            if self.state == "characters":
                self.draw_characters()
                pygame.display.flip()
                await asyncio.sleep(0)
                continue
            if self.state == "achievements":
                self.draw_achievements()
                pygame.display.flip()
                await asyncio.sleep(0)
                continue
            self.update(dt)
            self.draw_world()
            self.draw_hud()
            self.draw_title_hint()
            if self.state in ("upgrade", "chest"):
                self.draw_upgrade()
            elif self.state == "paused":
                self.draw_pause()
            elif self.state in ("game_over", "victory"):
                self.draw_game_over()
            pygame.display.flip()
            await asyncio.sleep(0)


async def main():
    game = Game()
    await game.run()


if __name__ == "__main__":
    asyncio.run(main())
