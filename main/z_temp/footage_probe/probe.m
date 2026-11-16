v = VideoReader('C:\Users\BOWN1111PC1\Downloads\experiment_video.MOV');
fprintf('dur %.3f fps %.4f size %dx%d frames %d fmt %s\n', v.Duration, v.FrameRate, v.Width, v.Height, v.NumFrames, v.VideoFormat);
out = 'C:\Users\BOWN1111PC1\Documents\Mohamed\experimental_osi\main\z_temp\footage_probe';
for t = [1 60 120 180 240 300 360 405]
    v.CurrentTime = t; I = readFrame(v);
    imwrite(imresize(I, 0.5), fullfile(out, sprintf('f_%03d.jpg', t)));
end
