import pygame
import random
import sys
from ui import GameUI

# Initialize Pygame
pygame.init()

# Define colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (255, 0, 0)
GREEN = (0, 255, 0)

# Set up game window
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
BLOCK_SIZE = 20
GAME_SPEED = 15

# Create game window
screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
pygame.display.set_caption('Snake Game')
clock = pygame.time.Clock()

# Initialize UI
game_ui = GameUI(WINDOW_WIDTH, WINDOW_HEIGHT)

class Snake:
    def __init__(self):
        self.length = 1
        self.positions = [(WINDOW_WIDTH//2, WINDOW_HEIGHT//2)]
        self.direction = random.choice([UP, DOWN, LEFT, RIGHT])
        self.color = GREEN
        self.score = 0

    def get_head_position(self):
        return self.positions[0]

    def update(self):
        cur = self.get_head_position()
        x, y = self.direction
        new = (cur[0] + (x*BLOCK_SIZE), cur[1] + (y*BLOCK_SIZE))
        
        # Check if hit wall
        if (new[0] < 0 or new[0] >= WINDOW_WIDTH or 
            new[1] < 0 or new[1] >= WINDOW_HEIGHT):
            return False
        
        # Check if hit itself
        if new in self.positions[3:]:
            return False
            
        self.positions.insert(0, new)
        if len(self.positions) > self.length:
            self.positions.pop()
        return True

    def reset(self):
        self.length = 1
        self.positions = [(WINDOW_WIDTH//2, WINDOW_HEIGHT//2)]
        self.direction = random.choice([UP, DOWN, LEFT, RIGHT])
        self.score = 0

    def render(self):
        for p in self.positions:
            pygame.draw.rect(screen, self.color, (p[0], p[1], BLOCK_SIZE, BLOCK_SIZE))

class Food:
    def __init__(self):
        self.position = (0, 0)
        self.color = RED
        self.randomize_position()

    def randomize_position(self):
        self.position = (random.randint(0, (WINDOW_WIDTH-BLOCK_SIZE)//BLOCK_SIZE) * BLOCK_SIZE,
                        random.randint(0, (WINDOW_HEIGHT-BLOCK_SIZE)//BLOCK_SIZE) * BLOCK_SIZE)

    def render(self):
        pygame.draw.rect(screen, self.color, (self.position[0], self.position[1], BLOCK_SIZE, BLOCK_SIZE))

# Define directions
UP = (0, -1)
DOWN = (0, 1)
LEFT = (-1, 0)
RIGHT = (1, 0)

def main():
    snake = Snake()
    food = Food()
    game_active = True

    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN and game_active:
                if event.key == pygame.K_UP and snake.direction != DOWN:
                    snake.direction = UP
                elif event.key == pygame.K_DOWN and snake.direction != UP:
                    snake.direction = DOWN
                elif event.key == pygame.K_LEFT and snake.direction != RIGHT:
                    snake.direction = LEFT
                elif event.key == pygame.K_RIGHT and snake.direction != LEFT:
                    snake.direction = RIGHT

        if game_active:
            # Update snake position
            if not snake.update():
                game_active = False
                game_ui.show_game_over_screen(screen, snake.score)
                # Restart game
                snake.reset()
                food.randomize_position()
                game_active = True
                continue

            # Check if food is eaten
            if snake.get_head_position() == food.position:
                snake.length += 1
                snake.score += 1
                food.randomize_position()

            # Draw game screen
            screen.fill(BLACK)
            snake.render()
            food.render()
            
            # Display score
            game_ui.draw_score(screen, snake.score)

            pygame.display.update()
            clock.tick(GAME_SPEED)

if __name__ == '__main__':
    main() 