import pygame
import sys

class GameUI:
    def __init__(self, screen_width, screen_height):
        self.screen_width = screen_width
        self.screen_height = screen_height
        self.font_big = pygame.font.Font(None, 72)
        self.font_small = pygame.font.Font(None, 36)
        
    def draw_score(self, screen, score):
        score_text = self.font_small.render(f'Score: {score}', True, (255, 255, 255))
        screen.blit(score_text, (10, 10))
    
    def show_game_over_screen(self, screen, score):
        # Game over text
        game_over_text = self.font_big.render('GAME OVER', True, (255, 255, 255))
        game_over_rect = game_over_text.get_rect(center=(self.screen_width/2, self.screen_height/2 - 50))
        
        # Final score text
        final_score_text = self.font_small.render(f'Final Score: {score}', True, (255, 255, 255))
        final_score_rect = final_score_text.get_rect(center=(self.screen_width/2, self.screen_height/2 + 20))
        
        # Restart prompt text
        restart_text = self.font_small.render('Press SPACE to Restart', True, (255, 255, 255))
        restart_rect = restart_text.get_rect(center=(self.screen_width/2, self.screen_height/2 + 70))
        
        # Draw all text
        screen.fill((0, 0, 0))
        screen.blit(game_over_text, game_over_rect)
        screen.blit(final_score_text, final_score_rect)
        screen.blit(restart_text, restart_rect)
        pygame.display.update()
        
        # Wait for player to press space to restart
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