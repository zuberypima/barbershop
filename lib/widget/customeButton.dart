import 'package:barber/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget customeButton(String lable) {
  return Container(
    height: 40,
    decoration: BoxDecoration(
      color: mainColor,
      border: Border.all(color: white),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Center(
      child: Text(
        lable,
        style: GoogleFonts.poppins(
          color: white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
