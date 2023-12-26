clc;
clear;
%=====================================
%   global variable
%=====================================
PATNUM = 50;
inputfile = "input.txt";
outputfile = "output.txt";

%=====================================
%   main
%=====================================
input = fopen(inputfile, 'wt');
output = fopen(outputfile, 'wt');

fprintf(input, "%d\n", PATNUM);
for patcount = 1 : PATNUM

    % For debugging easily, matrix size of first 20 patterns would be 2 * 2 intentionally
    if (patcount < 10)
        matrix_size = 0;
    elseif (patcount < 20)
        matrix_size = 1;
    else
        matrix_size = randi([0 3]);
    end
    
    size = getSize(matrix_size);

    % write matrix_size first
    fprintf(input, '%d\n', matrix_size);

    % initialize 32 matrix
    matrix = zeros(size, size, 32);

    % save random value into the 32 matrix
    % and write it into input.txt
    for idx = 1 : 32
        for row = 1 : size
            for col = 1 : size
                matrix(row, col, idx) = randi([0 20]);
                fprintf(input, "%4d", matrix(row, col, idx));

                if (col == size)
                    fprintf(input, "\n");
                end
            end
        end
    end

    % After initialize 32 matrix, start to generate mode and matrix_idx
    % and then compute the golden_ans
    for pat = 1 : 10
        % write mode into input.txt
        mode = randi([0 3]);
        fprintf(input, "%d\n", mode);

        % write matrix_idx into input.txt
        matrix_idx = zeros(3, 1);
        for i = 1 : 3
            matrix_idx(i) = randi([0 31]);
            fprintf(input, "%3d", matrix_idx(i));
        end
        fprintf(input, "\n");

        % initialize 3 matrix as A, B and C seperately
        A = matrix( : , : , matrix_idx(1) + 1);
        B = matrix( : , : , matrix_idx(2) + 1);
        C = matrix( : , : , matrix_idx(3) + 1);

        if mode == 1
            A = transpose(A);
        elseif mode == 2
            B = transpose(B);
        elseif mode == 3
            C = transpose(C);
        end

        product = A * B * C;

        % write golden_ans into output.txt
        out_value = trace(product);
        fprintf(output, "%d\n", out_value);

    end

end


%=====================================
%   function
%=====================================
function [size] = getSize(k)
    if k == 0
        size = 2;
    elseif k == 1
        size = 4;
    elseif k == 2
        size = 8;
    else
        size = 16;
    end
end