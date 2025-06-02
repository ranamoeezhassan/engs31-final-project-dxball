% Read image
im = imread('game_over.bmp');  % or any bmp file

% Get image size
[height, width, ~] = size(im);

% Prepare output vector
% Each pixel will be represented as a 12-bit value, packed into a 16-bit integer for convenience
% We'll just align the 12 bits in the lower part of the 16 bits

coevector = zeros(height*width,1,'uint16');

% Loop through image pixels row-major order
idx = 1;
for y = 1:height
    for x = 1:width
        r = im(y,x,1);
        g = im(y,x,2);
        b = im(y,x,3);
        
        % Take top 4 bits of each color (0-255 scaled to 0-15)
        r4 = bitshift(r, -4);  % 8bit to 4bit
        g4 = bitshift(g, -4);
        b4 = bitshift(b, -4);
        
        % Compose 12-bit color: r4(11:8), g4(7:4), b4(3:0)
        color12 = bitor(bitshift(uint16(r4),8), bitshift(uint16(g4),4));
        color12 = bitor(color12, uint16(b4));
        
        % Store 12 bits in lower bits of 16bit word (upper 4 bits zero)
        coevector(idx) = color12;
        idx = idx + 1;
    end
end

% Open file to write
fid = fopen('game_over.coe','w');

fprintf(fid, 'memory_initialization_radix=16;\n');
fprintf(fid, 'memory_initialization_vector=\n');

% Write all pixel data as hex, separated by commas
for i = 1:length(coevector)
    if i < length(coevector)
        fprintf(fid, '%03X,\n', coevector(i));  % 3 hex digits = 12 bits
    else
        fprintf(fid, '%03X;\n', coevector(i));  % last value ends with ;
    end
end

fclose(fid);
disp('COE file generated successfully.');