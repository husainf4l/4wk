import { Routes } from '@angular/router';
import { ComingSoonComponent } from './coming-soon/coming-soon.component';

export const routes: Routes = [
    { path: '', redirectTo: 'coming-soon', pathMatch: 'full' },
    { path: 'coming-soon', component: ComingSoonComponent },
];
