import pygame
import sys
import random
import math
from ui import GameUI

# Initialize Pygame
pygame.init()

# Define colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
BLUE = (0, 0, 255)
YELLOW = (255, 255, 0)
RED = (255, 0, 0)
PINK = (255, 182, 255)
CYAN = (0, 255, 255)
ORANGE = (255, 182, 85)

# Set up game window
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
BLOCK_SIZE = 30
GAME_SPEED = 60  # 保持60FPS

# Create game window
screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
pygame.display.set_caption('Pac-Man')
clock = pygame.time.Clock()

# Initialize UI
game_ui = GameUI(WINDOW_WIDTH, WINDOW_HEIGHT)

# Define maze layout (0: empty, 1: wall, 2: dot, 3: power pellet)
MAZE = [
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
    [1,2,2,2,2,2,2,2,2,1,1,2,2,2,2,2,2,2,2,1],
    [1,2,1,1,2,1,1,1,2,1,1,2,1,1,1,2,1,1,2,1],
    [1,3,1,1,2,1,1,1,2,1,1,2,1,1,1,2,1,1,3,1],
    [1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
    [1,2,1,1,2,1,2,1,1,1,1,1,1,2,1,2,1,1,2,1],
    [1,2,2,2,2,1,2,2,2,1,1,2,2,2,1,2,2,2,2,1],
    [1,1,1,1,2,1,1,1,2,1,1,2,1,1,1,2,1,1,1,1],
    [1,2,2,2,2,1,2,2,2,2,2,2,2,2,1,2,2,2,2,1],
    [1,2,1,1,2,1,2,1,1,0,0,1,1,2,1,2,1,1,2,1],
    [1,2,2,2,2,2,2,1,0,0,0,0,1,2,2,2,2,2,2,1],
    [1,2,1,1,2,1,2,1,1,1,1,1,1,2,1,2,1,1,2,1],
    [1,2,2,2,2,1,2,2,2,2,2,2,2,2,1,2,2,2,2,1],
    [1,1,1,1,2,1,2,1,1,1,1,1,1,2,1,2,1,1,1,1],
    [1,2,2,2,2,2,2,2,2,1,1,2,2,2,2,2,2,2,2,1],
    [1,2,1,1,2,1,1,1,2,1,1,2,1,1,1,2,1,1,2,1],
    [1,3,2,1,2,2,2,2,2,2,2,2,2,2,2,2,1,2,3,1],
    [1,1,2,1,2,1,2,1,1,1,1,1,1,2,1,2,1,2,1,1],
    [1,2,2,2,2,1,2,2,2,1,1,2,2,2,1,2,2,2,2,1],
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
]

class Ghost:
    def __init__(self, x, y, color):
        self.x = x * BLOCK_SIZE
        self.y = y * BLOCK_SIZE
        self.color = color
        self.direction = random.choice([(0, 1), (0, -1), (1, 0), (-1, 0)])
        self.speed = 2  # 确保幽灵速度比Pacman慢
        self.scared = False
        self.scared_timer = 0
        
    def update(self, pacman):
        # If at grid center, maybe change direction
        if self.x % BLOCK_SIZE == 0 and self.y % BLOCK_SIZE == 0:
            possible_directions = []
            x, y = int(self.x / BLOCK_SIZE), int(self.y / BLOCK_SIZE)
            
            # Check all possible directions
            for dx, dy in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
                new_x, new_y = x + dx, y + dy
                if (0 <= new_x < len(MAZE[0]) and 
                    0 <= new_y < len(MAZE) and 
                    MAZE[new_y][new_x] != 1):
                    possible_directions.append((dx, dy))
            
            if possible_directions:
                if not self.scared:
                    # Target Pacman
                    target_x = int(pacman.x / BLOCK_SIZE)
                    target_y = int(pacman.y / BLOCK_SIZE)
                    
                    # Choose direction closest to Pacman
                    best_direction = min(possible_directions, 
                        key=lambda d: ((x + d[0] - target_x) ** 2 + 
                                     (y + d[1] - target_y) ** 2))
                    
                    # 80% chance to choose best direction, 20% random
                    if random.random() < 0.8:
                        self.direction = best_direction
                    else:
                        self.direction = random.choice(possible_directions)
                else:
                    # Run away from Pacman
                    target_x = int(pacman.x / BLOCK_SIZE)
                    target_y = int(pacman.y / BLOCK_SIZE)
                    
                    # Choose direction furthest from Pacman
                    best_direction = max(possible_directions, 
                        key=lambda d: ((x + d[0] - target_x) ** 2 + 
                                     (y + d[1] - target_y) ** 2))
                    self.direction = best_direction
        
        # Move in current direction
        self.x += self.direction[0] * self.speed
        self.y += self.direction[1] * self.speed
        
        # Update scared state
        if self.scared:
            self.scared_timer -= 1
            if self.scared_timer <= 0:
                self.scared = False
    
    def render(self):
        color = (0, 0, 255) if self.scared else self.color  # Blue when scared
        
        # Draw ghost body
        pygame.draw.circle(screen, color, 
                         (int(self.x + BLOCK_SIZE/2), 
                          int(self.y + BLOCK_SIZE/2)), 
                         int(BLOCK_SIZE/2))
        
        # Draw ghost skirt
        points = [
            (self.x, self.y + BLOCK_SIZE/2),
            (self.x + BLOCK_SIZE, self.y + BLOCK_SIZE/2),
            (self.x + BLOCK_SIZE, self.y + BLOCK_SIZE),
            (self.x + BLOCK_SIZE*3/4, self.y + BLOCK_SIZE*3/4),
            (self.x + BLOCK_SIZE/2, self.y + BLOCK_SIZE),
            (self.x + BLOCK_SIZE/4, self.y + BLOCK_SIZE*3/4),
            (self.x, self.y + BLOCK_SIZE)
        ]
        pygame.draw.polygon(screen, color, points)
        
        # Draw eyes
        eye_color = WHITE
        pupil_color = BLACK
        eye_radius = BLOCK_SIZE/6
        pupil_radius = BLOCK_SIZE/8
        
        # Left eye
        pygame.draw.circle(screen, eye_color,
                         (int(self.x + BLOCK_SIZE/3),
                          int(self.y + BLOCK_SIZE/3)), 
                         int(eye_radius))
        # Right eye
        pygame.draw.circle(screen, eye_color,
                         (int(self.x + BLOCK_SIZE*2/3),
                          int(self.y + BLOCK_SIZE/3)), 
                         int(eye_radius))
        
        if not self.scared:
            # Pupils follow Pacman
            dx = self.direction[0]
            dy = self.direction[1]
            
            # Left pupil
            pygame.draw.circle(screen, pupil_color,
                             (int(self.x + BLOCK_SIZE/3 + dx*2),
                              int(self.y + BLOCK_SIZE/3 + dy*2)), 
                             int(pupil_radius))
            # Right pupil
            pygame.draw.circle(screen, pupil_color,
                             (int(self.x + BLOCK_SIZE*2/3 + dx*2),
                              int(self.y + BLOCK_SIZE/3 + dy*2)), 
                             int(pupil_radius))

class Pacman:
    def __init__(self):
        self.x = BLOCK_SIZE * 10
        self.y = BLOCK_SIZE * 15
        self.direction = (0, 0)
        self.next_direction = (0, 0)
        self.speed = 5  # 增加速度
        self.score = 0
        self.mouth_angle = 0
        self.mouth_change = 5

    def reset(self):
        # Reset all attributes to initial values
        self.x = BLOCK_SIZE * 10
        self.y = BLOCK_SIZE * 15
        self.direction = (0, 0)
        self.next_direction = (0, 0)
        self.score = 0
        self.mouth_angle = 0
        self.mouth_change = 5

    def update(self):
        # 检查下一个方向是否可行
        if self.next_direction != (0, 0):
            next_x = self.x + self.next_direction[0] * self.speed
            next_y = self.y + self.next_direction[1] * self.speed
            grid_x = int(next_x / BLOCK_SIZE)
            grid_y = int(next_y / BLOCK_SIZE)
            
            # 如果下一个方向可行，立即改变方向
            if (0 <= grid_x < len(MAZE[0]) and 0 <= grid_y < len(MAZE) and 
                MAZE[grid_y][grid_x] != 1):
                self.direction = self.next_direction
                self.next_direction = (0, 0)  # 清除下一个方向

        # 在当前方向上移动
        if self.direction != (0, 0):
            next_x = self.x + self.direction[0] * self.speed
            next_y = self.y + self.direction[1] * self.speed
            grid_x = int(next_x / BLOCK_SIZE)
            grid_y = int(next_y / BLOCK_SIZE)

            if (0 <= grid_x < len(MAZE[0]) and 0 <= grid_y < len(MAZE) and 
                MAZE[grid_y][grid_x] != 1):
                self.x = next_x
                self.y = next_y
                
                # 收集豆子
                if MAZE[grid_y][grid_x] == 2:
                    MAZE[grid_y][grid_x] = 0
                    self.score += 10
                elif MAZE[grid_y][grid_x] == 3:
                    MAZE[grid_y][grid_x] = 0
                    self.score += 50
                    return True  # 返回是否吃到能量豆
        return False

    def render(self):
        # Draw Pac-Man as a circle with a mouth
        # First draw the full circle
        pygame.draw.circle(screen, YELLOW, 
                         (int(self.x + BLOCK_SIZE/2), int(self.y + BLOCK_SIZE/2)), 
                         int(BLOCK_SIZE/2 - 2))
        
        # Then draw the mouth
        if self.direction != (0, 0):  # Only show mouth when moving
            # Calculate mouth points
            center = (int(self.x + BLOCK_SIZE/2), int(self.y + BLOCK_SIZE/2))
            radius = BLOCK_SIZE/2 - 2
            
            # Calculate mouth direction
            angle = 0
            if self.direction == (1, 0):    # Right
                angle = 0
            elif self.direction == (-1, 0):  # Left
                angle = 180
            elif self.direction == (0, -1):  # Up
                angle = 90
            elif self.direction == (0, 1):   # Down
                angle = 270
            
            # Draw mouth triangle
            mouth_angle = self.mouth_angle * 3.14159 / 180  # Convert to radians
            point1 = (center[0], center[1])
            point2 = (center[0] + radius * math.cos(angle - mouth_angle),
                     center[1] - radius * math.sin(angle - mouth_angle))
            point3 = (center[0] + radius * math.cos(angle + mouth_angle),
                     center[1] - radius * math.sin(angle + mouth_angle))
            
            pygame.draw.polygon(screen, BLACK, [point1, point2, point3])

    def check_ghost_collision(self, ghost):
        # Calculate distance between Pacman and ghost
        dx = self.x - ghost.x
        dy = self.y - ghost.y
        distance = (dx ** 2 + dy ** 2) ** 0.5
        
        if distance < BLOCK_SIZE:
            if ghost.scared:
                ghost.x = BLOCK_SIZE * 10  # Reset ghost position
                ghost.y = BLOCK_SIZE * 10
                self.score += 200  # Bonus points for eating ghost
                return False
            else:
                return True  # Game over
        return False

def draw_maze():
    for y, row in enumerate(MAZE):
        for x, cell in enumerate(row):
            rect = (x * BLOCK_SIZE, y * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
            if cell == 1:  # Wall
                pygame.draw.rect(screen, BLUE, rect)
            elif cell == 2:  # Dot
                pygame.draw.circle(screen, WHITE,
                                 (x * BLOCK_SIZE + BLOCK_SIZE//2,
                                  y * BLOCK_SIZE + BLOCK_SIZE//2), 3)
            elif cell == 3:  # Power pellet
                pygame.draw.circle(screen, WHITE,
                                 (x * BLOCK_SIZE + BLOCK_SIZE//2,
                                  y * BLOCK_SIZE + BLOCK_SIZE//2), 8)

def main():
    pacman = Pacman()
    ghosts = [
        Ghost(10, 8, RED),     # Blinky
        Ghost(10, 10, PINK),   # Pinky
        Ghost(9, 10, CYAN),    # Inky
        Ghost(11, 10, ORANGE)  # Clyde
    ]
    game_active = True

    while True:
        # 处理输入
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

        # 持续检查按键状态
        if game_active:
            keys = pygame.key.get_pressed()
            if keys[pygame.K_UP]:
                pacman.next_direction = (0, -1)
            elif keys[pygame.K_DOWN]:
                pacman.next_direction = (0, 1)
            elif keys[pygame.K_LEFT]:
                pacman.next_direction = (-1, 0)
            elif keys[pygame.K_RIGHT]:
                pacman.next_direction = (1, 0)

            # 更新游戏状态
            power_pellet = pacman.update()  # 检查是否吃到能量豆
            
            if power_pellet:
                for ghost in ghosts:
                    ghost.scared = True
                    ghost.scared_timer = 300

            # 更新和检查幽灵
            for ghost in ghosts:
                ghost.update(pacman)
                if pacman.check_ghost_collision(ghost):
                    game_active = False
                    game_ui.show_game_over_screen(screen, pacman.score)
                    pacman.reset()
                    for g in ghosts:
                        g.__init__(g.x // BLOCK_SIZE, g.y // BLOCK_SIZE, g.color)
                    game_active = True
                    break

            # 绘制游戏画面
            screen.fill(BLACK)
            draw_maze()
            for ghost in ghosts:
                ghost.render()
            pacman.render()
            game_ui.draw_score(screen, pacman.score)
            
            pygame.display.update()
            clock.tick(GAME_SPEED)

if __name__ == '__main__':
    main() 