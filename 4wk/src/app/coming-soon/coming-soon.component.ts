import { Component, OnInit, Inject, PLATFORM_ID, Renderer2, ElementRef } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

@Component({
  selector: 'app-coming-soon',
  templateUrl: './coming-soon.component.html',
  styleUrls: ['./coming-soon.component.css']
})
export class ComingSoonComponent implements OnInit {
  private launchDate = new Date('2024-12-31T23:59:59'); // Set your target launch date

  constructor(
    @Inject(PLATFORM_ID) private platformId: Object, // Detect platform
    private renderer: Renderer2, // For safe DOM manipulation
    private el: ElementRef // Reference to the host element
  ) {}

  ngOnInit(): void {
    if (isPlatformBrowser(this.platformId)) {
      this.startCountdown(); // Only run countdown in the browser
    }
  }

  startCountdown() {
    const intervalId = setInterval(() => {
      const now = new Date().getTime();
      const timeLeft = this.launchDate.getTime() - now;

      const days = Math.floor(timeLeft / (1000 * 60 * 60 * 24));
      const hours = Math.floor((timeLeft % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
      const minutes = Math.floor((timeLeft % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((timeLeft % (1000 * 60)) / 1000);

      this.updateCountdown('days', days);
      this.updateCountdown('hours', hours);
      this.updateCountdown('minutes', minutes);
      this.updateCountdown('seconds', seconds);

      if (timeLeft < 0) {
        clearInterval(intervalId); // Stop the countdown if the date is reached
        this.displayCompleteMessage();
      }
    }, 1000);
  }

  private updateCountdown(elementId: string, value: number) {
    const element = this.el.nativeElement.querySelector(`#${elementId}`);
    if (element) {
      this.renderer.setProperty(element, 'innerText', this.formatNumber(value));
    }
  }

  private formatNumber(value: number): string {
    return value < 10 ? '0' + value : value.toString();
  }

  private displayCompleteMessage() {
    const content = this.el.nativeElement.querySelector('.content');
    if (content) {
      this.renderer.setProperty(content, 'innerHTML', '<h1>We are Live!</h1>');
    }
  }
}
