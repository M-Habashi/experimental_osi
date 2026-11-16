I = imread('rest_full.png'); G = double(rgb2gray(I));
rows = 120:20:1540; L = nan(size(rows)); R = L;
for i = 1:numel(rows)
    g = diff(mean(G(rows(i) + (-3:3), :), 1));
    [~, a] = max(-g(330:420)); L(i) = 329 + a;   % bright wall -> dark column
    [~, b] = max(abs(g(600:680))); R(i) = 599 + b;
end
pl = polyfit(rows, L, 1); pr = polyfit(rows, R, 1);
fprintf('left edge x = %.4f*y + %.1f, right x = %.4f*y + %.1f\n', pl, pr);
fprintf('roll %.2f deg (left), %.2f deg (right); width top %.0f px, bottom %.0f px\n', ...
    atand(-pl(1)), atand(-pr(1)), polyval(pr, 100) - polyval(pl, 100), polyval(pr, 1550) - polyval(pl, 1550));
imwrite(I(560:900, 860:1040, :), 'stencil.png'); imwrite(I(1450:1700, 250:800, :), 'base.png');
imwrite(I(200:420, 560:1080, :), 'actuator.png');
