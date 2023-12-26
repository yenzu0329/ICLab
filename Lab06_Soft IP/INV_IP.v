//===========================================================================
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : INV_IP.v
//   	Module Name : INV_IP
//===========================================================================

module INV_IP #(parameter IP_WIDTH = 6) (
    // Input signals
    IN_1, IN_2,
    // Output signals
    OUT_INV
);


// ===============================================================
// Declaration
// ===============================================================
input      [IP_WIDTH-1:0] IN_1, IN_2;
output reg [IP_WIDTH-1:0] OUT_INV;

// ===============================================================
// Soft IP DESIGN
// ===============================================================

genvar i, j, k;
generate
if(IP_WIDTH == 6) begin: gen_w6
    
    reg [IP_WIDTH-1: 0] y[4:0];
    reg [5: 0] a0;
    reg [4: 0] a1, a2, b0, b1;
    reg [3: 0] a3, b2;
    reg [2: 0] b3;

    reg [4: 0] q0, r0;
    reg [3: 0] q1, q2, r1;
    reg [2: 0] q3, r2;
    reg [1: 0] r3;
    reg [IP_WIDTH-1: 0] temp_b;
    reg [IP_WIDTH-1: 0] temp_out;
    reg temp_neg, neg;

    always @(*) begin
        temp_b = (IN_1 > IN_2) ? IN_2 : IN_1;
        temp_neg = temp_b > (a0 >> 1);
    end

    always @(*) begin
        a0 = (IN_1 > IN_2) ? IN_1 : IN_2;
        b0 = (temp_neg) ? (a0 - temp_b) : temp_b;
    end

    always @(*) begin
        a1 = b0;
        b1 = r0;
    end

    always @(*) begin
        a2 = b1;
        b2 = r1;
    end

    always @(*) begin
        a3 = b2;
        b3 = r2;
    end

    always @(*) begin
        q0 = a0 / b0;
        r0 = a0 % b0;
    end

    always @(*) begin
        q1 = a1 / b1;
        r1 = a1 % b1;
    end

    always @(*) begin
        q2 = a2 / b2;
        r2 = a2 % b2;
    end

    always @(*) begin
        q3 = a3 / b3;
        r3 = a3 % b3;
    end

    always @(*) begin
        y[0] = q0;
        y[1] = 1    + q1 * y[0];
        y[2] = y[0] + q2 * y[1];
        y[3] = y[1] + q3 * y[2];
        y[4] = y[2] + y[3];
    end

    always @(*) begin
        if(b0 == 1)       temp_out = 1;
        else if(r0 == 1)  temp_out = y[0];
        else if(r1 == 1)  temp_out = y[1];
        else if(r2 == 1)  temp_out = y[2];
        else if(r3 == 1)  temp_out = y[3];
        else              temp_out = y[4];
    end

    always @(*) begin
        if(b0 == 1 || r1 == 1 || r3 == 1) neg = temp_neg;
        else                              neg = ~temp_neg;
    end

    always @(*) begin
        if(b0 == 0)       OUT_INV = 0;
        else              OUT_INV = (neg) ? (a0-temp_out) : temp_out;
    end
end
else begin: gen_normal
    reg [IP_WIDTH-1: 0] y[IP_WIDTH-1:0];
    reg [IP_WIDTH-1: 0] a[IP_WIDTH-1:0];
    reg [IP_WIDTH-1: 0] b[IP_WIDTH-1:0];
    reg [IP_WIDTH-1: 0] q[IP_WIDTH-1:0];
    reg [IP_WIDTH-1: 0] r[IP_WIDTH-1:0];
    reg [IP_WIDTH-1: 0] temp_b;
    reg [IP_WIDTH-1: 0] temp_out;
    reg temp_neg, neg;

    always @(*) begin
        temp_b = (IN_1 > IN_2) ? IN_2 : IN_1;
        temp_neg = temp_b > (a[0] >> 1);
    end

    for(i=0; i<IP_WIDTH; i=i+1) begin: loop_ab
        if(i == 0) begin
            always @(*) begin
                a[i] = (IN_1 > IN_2) ? IN_1 : IN_2;
                b[i] = (temp_neg) ? (a[0] - temp_b) : temp_b;
            end
        end
        else begin
            always @(*) begin
                a[i] = b[i-1];
                b[i] = r[i-1];
            end
        end
    end

    for(j=0; j<IP_WIDTH; j=j+1) begin: loop_qr
        always @(*) begin
            q[j] = a[j] / b[j];
            r[j] = a[j] % b[j];
        end
    end

    for(k=0; k<IP_WIDTH; k=k+1) begin: loop_y
        if(k == 0) begin: loop_y_k0
            always @(*)  y[k] = q[k];
        end
        else if(k == 1) begin: loop_y_k1
            always @(*)  y[k] = 1 + q[k] * y[k-1];
        end
        else if(k == 6) begin: loop_y_k6
            always @(*)  y[k] = y[k-2] + y[k-1];
        end
        else begin: loop_y_else
            always @(*)  y[k] = y[k-2] + q[k] * y[k-1];
        end 
    end

    if(IP_WIDTH == 5) begin: sel_out_w5
        always @(*) begin
            if(b[0] == 1)       temp_out = 1;
            else if(r[0] == 1)  temp_out = y[0];
            else if(r[1] == 1)  temp_out = y[1];
            else if(r[2] == 1)  temp_out = y[2];
            else if(r[3] == 1)  temp_out = y[3];
            else                temp_out = y[4];
        end
        always @(*) begin
            if(b[0] == 1 || r[1] == 1 || r[3] == 1) neg = temp_neg;
            else                                    neg = ~temp_neg;
        end
    end
    else begin: sel_out_w7
        always @(*) begin
            if(b[0] == 1)       temp_out = 1;
            else if(r[0] == 1)  temp_out = y[0];
            else if(r[1] == 1)  temp_out = y[1];
            else if(r[2] == 1)  temp_out = y[2];
            else if(r[3] == 1)  temp_out = y[3];
            else if(r[4] == 1)  temp_out = y[4];
            else if(r[5] == 1)  temp_out = y[5];
            else                temp_out = y[6];
        end
        always @(*) begin
            if(b[0] == 1 || r[1] == 1 || r[3] == 1 || r[5] == 1) neg = temp_neg;
            else                                                 neg = ~temp_neg;
        end
    end

    always @(*) begin
        if(b[0] == 0)       OUT_INV = 0;
        else                OUT_INV = (neg) ? (a[0]-temp_out) : temp_out;
    end
end
endgenerate


endmodule