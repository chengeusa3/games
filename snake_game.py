import pygame
import random
import sys

# 初始化 Pygame
pygame.init()

# 定义颜色
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (255, 0, 0)
GREEN = (0, 255, 0)

# 设置游戏窗口
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
BLOCK_SIZE = 20
GAME_SPEED = 15

# 创建游戏窗口
screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
pygame.display.set_caption('贪吃蛇游戏')
clock = pygame.time.Clock()

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
        
        # 检查是否撞墙
        if (new[0] < 0 or new[0] >= WINDOW_WIDTH or 
            new[1] < 0 or new[1] >= WINDOW_HEIGHT):
            return False
        
        # 检查是否撞到自己
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

# 定义方向
UP = (0, -1)
DOWN = (0, 1)
LEFT = (-1, 0)
RIGHT = (1, 0)

def show_game_over_screen(screen, score):
    font_big = pygame.font.Font(None, 72)
    font_small = pygame.font.Font(None, 36)
    
    # 游戏结束文本
    game_over_text = font_big.render('游戏结束', True, WHITE)
    game_over_rect = game_over_text.get_rect(center=(WINDOW_WIDTH/2, WINDOW_HEIGHT/2 - 50))
    
    # 最终得分文本
    final_score_text = font_small.render(f'最终得分: {score}', True, WHITE)
    final_score_rect = final_score_text.get_rect(center=(WINDOW_WIDTH/2, WINDOW_HEIGHT/2 + 20))
    
    # 重新开始提示文本
    restart_text = font_small.render('按空格键重新开始', True, WHITE)
    restart_rect = restart_text.get_rect(center=(WINDOW_WIDTH/2, WINDOW_HEIGHT/2 + 70))
    
    # 绘制所有文本
    screen.fill(BLACK)
    screen.blit(game_over_text, game_over_rect)
    screen.blit(final_score_text, final_score_rect)
    screen.blit(restart_text, restart_rect)
    pygame.display.update()
    
    # 等待玩家按空格键重新开始
    waiting = True
    while waiting:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_SPACE:
                    waiting = False
                elif event.key == pygame.K_q:
                    pygame.quit()
                    sys.exit()

def main():
    snake = Snake()
    food = Food()
    font = pygame.font.Font(None, 36)
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
            # 更新蛇的位置
            if not snake.update():
                game_active = False
                show_game_over_screen(screen, snake.score)
                # 重新开始游戏
                snake.reset()
                food.randomize_position()
                game_active = True
                continue

            # 检查是否吃到食物
            if snake.get_head_position() == food.position:
                snake.length += 1
                snake.score += 1
                food.randomize_position()

            # 绘制游戏界面
            screen.fill(BLACK)
            snake.render()
            food.render()
            
            # 显示分数
            score_text = font.render(f'分数: {snake.score}', True, WHITE)
            screen.blit(score_text, (10, 10))

            pygame.display.update()
            clock.tick(GAME_SPEED)

if __name__ == '__main__':
    main() 